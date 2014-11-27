class CreateKeywords < ActiveRecord::Migration
  def change
    create_table :keywords do |t|
      t.text :name, :limit=>255

      t.timestamps
    end
    add_index :keywords, :name, unique: true, :length => { :name => 255 }
  end
end
