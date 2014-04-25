class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name

      t.timestamps
    end
    
    create_table :movies_companies do |t|
      t.belongs_to :movie
      t.belongs_to :company
    end
  end
end
