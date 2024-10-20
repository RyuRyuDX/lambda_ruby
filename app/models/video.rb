class Video < ApplicationRecord
  def self.search_and_save_youtube(query, max_results:, published_after:, min_subscribers: 1000)
    youtube_videos = search_youtube(query, max_results, published_after, min_subscribers)

    youtube_videos.each do |video_data|
      unless Video.exists?(title: video_data[:title], channel: video_data[:channel_title])
        engagement_score = video_data[:view_count] * 0.5 + video_data[:like_count] * 0.3 + video_data[:comment_count] * 0.2

        if video_data[:subscriber_count] >= min_subscribers && engagement_score >= 50
          video = Video.create(
            url: video_data[:watch_url],
            title: video_data[:title],
            published_at: video_data[:published_at],
            channel: video_data[:channel_title],
            subs: video_data[:subscriber_count],
            engagement_score: engagement_score
          )
        end
      end
    end
  end

  def self.search_youtube(query, max_results, published_after, min_subscribers)
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    youtube.key = Rails.env.production? ? ENV['YOUTUBE_API_KEY'] : YAML.load_file(Rails.root.join('config', 'youtube_api.yml'))['DEVELOPER_KEY']

    search_options = {
      q: query,
      max_results: max_results * 2,
      type: 'video',
      order: 'date',
      published_after: published_after
    }

    search_response = youtube.list_searches('snippet', **search_options)
    video_ids = search_response.items.map { |item| item.id.video_id }.uniq
    videos_response = youtube.list_videos('snippet,statistics', id: video_ids.join(','))

    channel_ids = search_response.items.map { |item| item.snippet.channel_id }.uniq
    channels_response = youtube.list_channels('snippet,statistics', id: channel_ids.join(','))
    channels = channels_response.items.select { |channel| channel.statistics.subscriber_count.to_i >= min_subscribers }
    valid_channel_ids = channels.map(&:id)

    videos = videos_response.items.select { |video| valid_channel_ids.include?(video.snippet.channel_id) }
      .map do |video|
        channel = channels.find { |c| c.id == video.snippet.channel_id }
        {
          title: video.snippet.title,
          published_at: video.snippet.published_at,
          channel_title: video.snippet.channel_title,
          subscriber_count: channel.statistics.subscriber_count.to_i,
          view_count: video.statistics.view_count.to_i,       # 視聴回数
          like_count: video.statistics.like_count.to_i,       # いいね数
          comment_count: video.statistics.comment_count.to_i, # コメント数
          watch_url: "https://www.youtube.com/watch?v=#{video.id}"
        }
      end
      .sort_by { |video| -video[:subscriber_count] }
      .first(max_results)

    videos
  rescue Google::Apis::Error => e
    Rails.logger.error "YouTube API error: #{e.message}"
    []
  end
end
