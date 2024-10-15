class FixColumnNameInVideos < ActiveRecord::Migration[7.1]
  def change
    rename_column :videos, :chennel, :channel
  end
end
