class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.text :name

      t.timestamps
    end
    add_index :countries, :name, unique: true
  end
end
