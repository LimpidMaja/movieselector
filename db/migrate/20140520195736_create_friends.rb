class CreateFriends < ActiveRecord::Migration
  def change
    create_table :friends do |t|
      t.integer :user_id
      t.integer :friend_id
      t.string :facebook_id
      t.boolean :friend_confirm

      t.timestamps
    end
  end
end
