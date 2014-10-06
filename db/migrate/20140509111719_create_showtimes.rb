class CreateShowtimes < ActiveRecord::Migration
  def change
    create_table :showtimes do |t|
      t.integer :movie_id
      t.string :title
      t.string :original_title
      t.string :cinema
      t.time :time
      t.date :date
      t.boolean :is_3d
      t.boolean :is_synchronized
      t.string :city
      t.string :country
      t.string :state

      t.timestamps
    end
  end
end
