class ChangeForFriendly2 < ActiveRecord::Migration
  def up
    add_column   :languages, :slug, :string, unique: true 
    add_column   :countries, :slug, :string, unique: true 
    add_column   :actors, :slug, :string, unique: true    
    add_column   :directors, :slug, :string, unique: true    
    add_column   :genres, :slug, :string, unique: true    
    add_column   :keywords, :slug, :string, unique: true    
    add_column   :writers, :slug, :string, unique: true    
    add_column   :movies, :slug, :string, unique: true      
  end

  def down
    remove_column :languages, :slug, :string
    remove_column :countries, :slug, :string
    remove_column :actors, :slug, :string
    remove_column :directors, :slug, :string
    remove_column :genres, :slug, :string
    remove_column :keywords, :slug, :string
    remove_column :writers, :slug, :string
    remove_column :movies, :slug, :string
  end
end
