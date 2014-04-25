class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.text :name

      t.timestamps
    end
    add_index :languages, :name, unique: true
  end
end
