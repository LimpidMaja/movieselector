class Company < ActiveRecord::Base
  extend FriendlyId  
  friendly_id :name, use: :slugged
  paginates_per 50
  searchkick word_start: [:name], suggest: ["name"]
  
  has_and_belongs_to_many :movies, join_table: :movies_companies
end
