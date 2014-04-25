class CreateDirectors < ActiveRecord::Migration
  def change
    create_table :directors do |t|
      t.text :name
      t.text :lastname

      t.timestamps
    end
  end
end
