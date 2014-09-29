class Favorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :anagram
  has_one :phrase, through: :anagram
  has_one :child, through: :anagram
end
