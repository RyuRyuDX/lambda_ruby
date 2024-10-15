class CreateVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :videos do |t|
      t.string :title
      t.text :url
      t.datetime :published_at
      t.string :chennel
      t.integer :subs

      t.timestamps
    end
  end
end
