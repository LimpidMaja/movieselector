class CreateKeywords < ActiveRecord::Migration
  def change
    create_table :keywords do |t|
      t.text :name

      t.timestamps
    end
    add_index :keywords, :name, unique: true
  end
end
