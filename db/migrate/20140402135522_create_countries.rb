class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.text :name, :limit=>255

      t.timestamps
    end
    add_index :countries, :name, unique: true, :length => { :name => 255 }
  end
end
