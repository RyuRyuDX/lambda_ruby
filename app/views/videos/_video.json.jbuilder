json.extract! video, :id, :title, :url, :published_at, :chennel, :subs, :created_at, :updated_at
json.url video_url(video, format: :json)
