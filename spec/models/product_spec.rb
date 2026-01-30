require 'rails_helper'

RSpec.describe Product, type: :model do
  context 'when validating' do
    it 'validates presence of name' do
      product = described_class.new(price: 100)
      expect(product.valid?).to be_falsey
      expect(product.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of price' do
      product = described_class.new(name: 'name')
      expect(product.valid?).to be_falsey
      expect(product.errors[:price]).to include("can't be blank")
    end

    it 'validates numericality of price' do
      product = described_class.new(price: -1)
      expect(product.valid?).to be_falsey
      expect(product.errors[:price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'associations' do
    it 'has many cart_products' do
      product = described_class.new
      expect(product.cart_products).to be_a(ActiveRecord::Relation)
    end

    it 'has many carts' do
      product = described_class.new
      expect(product.carts).to be_a(ActiveRecord::Relation)
    end
  end
end
