class CreateActors < ActiveRecord::Migration
  def change
    create_table :actors do |t|
      t.text :name
      t.text :lastname

      t.timestamps
    end
  end
end
