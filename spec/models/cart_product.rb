require 'rails_helper'

RSpec.describe CartProduct, type: :model do
  context 'when validating' do
    it 'validates presence of quantity' do
      cart_product = described_class.new(quantity: nil)
      expect(cart_product.valid?).to be_falsey
      expect(cart_product.errors[:quantity]).to include("can't be blank")
    end

    context 'numericality of quantity' do
      it 'validates numericality of quantity' do
        cart_product = described_class.new(quantity: -1)
        expect(cart_product.valid?).to be_falsey
        expect(cart_product.errors[:quantity]).to include("must be greater than 0")
      end
  
      it 'validates numericality of quantity' do
        cart_product = described_class.new(quantity: 0)
        expect(cart_product.valid?).to be_falsey
        expect(cart_product.errors[:quantity]).to include("must be greater than 0")
      end
    end
  end

  describe 'associations' do
    it 'belongs to cart' do
      cart_product = described_class.new
      expect(cart_product).to belong_to(:cart)
    end

    it 'belongs to product' do
      cart_product = described_class.new
      expect(cart_product).to belong_to(:product)
    end
  end

  describe '#total_price' do
    it 'returns the product price times quantity' do
      product = Product.create!(name: "Sample", price: 9.99)
      cart = Cart.create!
      cart_product = described_class.new(product: product, cart: cart, quantity: 3)
      expect(cart_product.total_price).to eq(9.99 * 3)
    end
  end
end