class Flat < ApplicationRecord
  has_many :tags
  has_many :prices
end
