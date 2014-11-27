class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.text :name, :limit=>255

      t.timestamps
    end
    add_index :languages, :name, unique: true, :length => { :name => 255 }
  end
end
