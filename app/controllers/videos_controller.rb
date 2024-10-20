class VideosController < ApplicationController
  before_action :set_video, only: %i[show edit update destroy]

  def index
    @videos = Video.all

    case params[:sort]
    when 'newest'
      @videos = @videos.order(published_at: :DESC)
    when 'oldest'
      @videos = @videos.order(published_at: :ASC)
    when 'subscribers_desc'
      @videos = @videos.order(subs: :DESC)
    when 'subscribers_asc'
      @videos = @videos.order(subs: :ASC)
    else
      @videos = @videos.order(created_at: :DESC)
    end

    @videos = @videos.page(params[:page]).per(50)
  end

  def show
  end

  def new
    @video = Video.new
    @youtube_videos = Video.search_and_save_youtube('緊急', 50, false, 10000)
    redirect_to videos_path, notice: 'New videos have been fetched and saved.'
  end

  def edit
  end

  def create
    @video = Video.new(video_params)

    respond_to do |format|
      if @video.save
        format.html { redirect_to @video, notice: "Video was successfully created." }
        format.json { render :show, status: :created, location: @video }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @video.update(video_params)
        format.html { redirect_to @video, notice: "Video was successfully updated." }
        format.json { render :show, status: :ok, location: @video }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @video.destroy!

    respond_to do |format|
      format.html { redirect_to videos_path, status: :see_other, notice: "Video was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def fetch_videos
    min_subscribers = params[:min_subscribers].to_i
    days_ago = params[:days_ago].to_i
    max_results = params[:max_results].to_i

    published_after = days_ago.days.ago.strftime('%Y-%m-%dT00:00:00Z')

    @youtube_videos = Video.search_and_save_youtube('緊急で', max_results: max_results, published_after: published_after, min_subscribers: min_subscribers)
    redirect_to videos_path, notice: 'New videos have been fetched and saved.'
  end

  private

  def set_video
    @video = Video.find(params[:id])
  end

  def video_params
    params.require(:video).permit(:title, :url, :published_at, :channel, :subs)
  end
end
