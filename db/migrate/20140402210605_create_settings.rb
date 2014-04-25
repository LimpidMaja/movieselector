class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.boolean :private
      t.string :trakt_username
      t.string :trakt_password

      t.timestamps
    end
  end
end
