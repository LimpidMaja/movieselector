class CreateEventUserVotes < ActiveRecord::Migration
  def change
    create_table :event_user_votes do |t|
      t.integer :movie_id
      t.integer :event_id
      t.integer :user_id
      t.integer :score

      t.timestamps
    end
  end
end

 