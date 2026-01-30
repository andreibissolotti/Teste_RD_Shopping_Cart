class Product < ApplicationRecord
  validates_presence_of :name, :price
  validates_numericality_of :price, greater_than_or_equal_to: 0
  has_many :cart_products, dependent: :destroy
  has_many :carts, through: :cart_products
end
