class Address < ApplicationRecord
  belongs_to :company

  validates :street, presence: true
  validates :city, presence: true
  validates :country, presence: true
end
