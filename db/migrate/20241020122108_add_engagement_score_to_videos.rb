class AddEngagementScoreToVideos < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :engagement_score, :float
  end
end
