require 'google/apis/youtube_v3'
require 'json'
require 'date'
require 'yaml'

YOUTUBE_API_SERVICE_NAME = 'youtube'
YOUTUBE_API_VERSION = 'v3'

def youtube_search(query, max_results, today_only = false, min_subscribers = 1000)
  config = YAML.load_file('config.yml')

  youtube = Google::Apis::YoutubeV3::YouTubeService.new
  youtube.key = config['DEVELOPER_KEY']

  begin
    search_options = {
      q: query,
      max_results: max_results * 2,
      type: 'video',
      order: 'date'
    }

    if today_only
      today = Date.today
      search_options[:published_after] = today.strftime('%Y-%m-%dT00:00:00Z')
    end

    search_response = youtube.list_searches('snippet', **search_options)

    videos = []
    channel_ids = search_response.items.map { |item| item.snippet.channel_id }.uniq

    channels_response = youtube.list_channels('snippet,statistics', id: channel_ids.join(','))
    channels = channels_response.items.select { |channel| channel.statistics.subscriber_count.to_i >= min_subscribers }
    valid_channel_ids = channels.map(&:id)

    search_response.items.each do |search_result|
      if valid_channel_ids.include?(search_result.snippet.channel_id)
        channel = channels.find { |c| c.id == search_result.snippet.channel_id }
        videos << {
          title: search_result.snippet.title,
          video_id: search_result.id.video_id,
          published_at: search_result.snippet.published_at,
          channel_title: search_result.snippet.channel_title,
          subscriber_count: channel.statistics.subscriber_count.to_i,
          watch_url: "https://www.youtube.com/watch?v=#{search_result.id.video_id}"
        }
      end

      break if videos.size >= max_results
    end

    # チャンネル登録者数の降順でソート
    videos.sort_by! { |video| -video[:subscriber_count] }

    puts "チャンネル登録者数#{min_subscribers}人以上のチャンネルの動画（登録者数順）："
    puts

    if videos.empty?
      puts "指定された条件に合う動画は見つかりませんでした。"
    else
      videos.each do |video|
        puts "タイトル：#{video[:title]}"
        puts "動画ID：#{video[:video_id]}"
        puts "視聴URL：#{video[:watch_url]}"
        puts "公開日時：#{video[:published_at]}"
        puts "チャンネル：#{video[:channel_title]}（登録者数：#{video[:subscriber_count]}人）"
        puts "---"
        puts
      end
    end
  rescue Google::Apis::Error => e
    puts "エラーが発生しました：#{e.message}"
  end
end

if __FILE__ == $0
  youtube_search('緊急', 5, false, 1000)
end