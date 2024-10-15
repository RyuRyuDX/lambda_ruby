require 'google/apis/youtube_v3'

class Video < ApplicationRecord
  def self.search_and_save_youtube(query, max_results, today_only = false, min_subscribers = 1000)
    youtube_videos = search_youtube(query, max_results, today_only, min_subscribers)

    youtube_videos.map do |video_data|
      Video.create_or_find_by(url: video_data[:watch_url]) do |video|
        video.title = video_data[:title]
        video.published_at = video_data[:published_at]
        video.channel = video_data[:channel_title]
        video.subs = video_data[:subscriber_count]
      end
    end
  end

  def self.search_youtube(query, max_results, today_only = false, min_subscribers = 1000)
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    youtube.key = Rails.env.production? ? ENV['YOUTUBE_API_KEY'] : YAML.load_file(Rails.root.join('config', 'youtube_api.yml'))['DEVELOPER_KEY']

    search_options = {
      q: query,
      max_results: max_results * 2,
      type: 'video',
      order: 'date'
    }

    search_options[:published_after] = Date.today.strftime('%Y-%m-%dT00:00:00Z') if today_only

    search_response = youtube.list_searches('snippet', **search_options)
    channel_ids = search_response.items.map { |item| item.snippet.channel_id }.uniq
    channels_response = youtube.list_channels('snippet,statistics', id: channel_ids.join(','))
    channels = channels_response.items.select { |channel| channel.statistics.subscriber_count.to_i >= min_subscribers }
    valid_channel_ids = channels.map(&:id)

    videos = search_response.items.select { |search_result| valid_channel_ids.include?(search_result.snippet.channel_id) }
      .map do |search_result|
        channel = channels.find { |c| c.id == search_result.snippet.channel_id }
        {
          title: search_result.snippet.title,
          published_at: search_result.snippet.published_at,
          channel_title: search_result.snippet.channel_title,
          subscriber_count: channel.statistics.subscriber_count.to_i,
          watch_url: "https://www.youtube.com/watch?v=#{search_result.id.video_id}"
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
