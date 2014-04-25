class Keyword < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  searchkick word_start: [:name], suggest: ["name"]
  has_and_belongs_to_many :movies, join_table: :movies_keywords
end
