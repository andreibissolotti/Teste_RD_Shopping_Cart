class Cart < ApplicationRecord
  validates_numericality_of :total_price, greater_than_or_equal_to: 0
  has_many :cart_products, dependent: :destroy
  has_many :products, through: :cart_products
  
  before_validation :set_default_total_price, on: :create

  private

  def set_default_total_price
    self.total_price ||= 0
  end
  # TODO: lógica para marcar o carrinho como abandonado e remover se abandonado
end
