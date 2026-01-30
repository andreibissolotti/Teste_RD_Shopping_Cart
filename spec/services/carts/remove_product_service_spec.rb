require 'rails_helper'

RSpec.describe Carts::RemoveProductService do
  let(:cart) { create(:cart) }
  let(:product) { create(:product, price: 15.0) }

  describe '.call' do
    context 'when product is in the cart with quantity > 1 (unitary removal - default)' do
      let!(:cart_product) { create(:cart_product, cart: cart, product: product, quantity: 3) }

      before do
        cart.update!(total_price: 45.0)
      end

      it 'does not destroy cart_product when quantity > 1' do
        expect { described_class.call(cart, product.id) }.not_to change(CartProduct, :count)
      end

      it 'decrements quantity by 1 and keeps product in cart' do
        result = described_class.call(cart, product.id)

        expect(result[:status]).to eq(:ok)
        expect(cart_product.reload.quantity).to eq(2)
      end

      it 'recalculates cart total_price' do
        result = described_class.call(cart, product.id)

        expect(result[:cart].total_price).to eq(30.0)
      end

      it 'returns cart with updated product' do
        result = described_class.call(cart, product.id)

        expect(result[:cart].cart_products.first.quantity).to eq(2)
      end
    end

    context 'when product has quantity 1 (unitary removal - removes entirely)' do
      let!(:cart_product) { create(:cart_product, cart: cart, product: product, quantity: 1) }

      before do
        cart.update!(total_price: 15.0)
      end

      it 'removes the product from the cart' do
        expect {
          described_class.call(cart, product.id)
        }.to change(CartProduct, :count).by(-1)
      end

      it 'returns cart with empty products and total_price zero' do
        result = described_class.call(cart, product.id)

        expect(result[:status]).to eq(:ok)
        expect(result[:cart].cart_products).to be_empty
        expect(result[:cart].total_price).to eq(0)
      end
    end

    context 'when remove_all is true (total removal)' do
      let!(:cart_product) { create(:cart_product, cart: cart, product: product, quantity: 2) }

      before do
        cart.update!(total_price: 30.0)
      end

      it 'removes the product entirely from the cart' do
        expect {
          described_class.call(cart, product.id, remove_all: true)
        }.to change(CartProduct, :count).by(-1)
      end

      it 'returns cart with empty products and total_price zero' do
        result = described_class.call(cart, product.id, remove_all: true)

        expect(result[:status]).to eq(:ok)
        expect(result[:cart].cart_products).to be_empty
        expect(result[:cart].total_price).to eq(0)
      end
    end

    context 'when cart has multiple products (unitary removal)' do
      let(:product_b) { create(:product, price: 10.0) }
      let!(:cart_product_a) { create(:cart_product, cart: cart, product: product, quantity: 2) }
      let!(:cart_product_b) { create(:cart_product, cart: cart, product: product_b, quantity: 2) }

      before do
        cart.update!(total_price: 50.0)
      end

      it 'decrements only the specified product' do
        result = described_class.call(cart, product.id)

        expect(result[:cart].cart_products.count).to eq(2)
        expect(result[:cart].cart_products.find_by(product: product).quantity).to eq(1)
        expect(result[:cart].cart_products.find_by(product: product_b).quantity).to eq(2)
      end

      it 'recalculates total_price correctly' do
        result = described_class.call(cart, product.id)

        expect(result[:cart].total_price).to eq(35.0)
      end
    end

    context 'when product is not in the cart' do
      it 'returns errors with status not_found' do
        result = described_class.call(cart, product.id)

        expect(result[:status]).to eq(:not_found)
        expect(result[:errors]).to include('Produto não encontrado no carrinho')
      end

      it 'does not remove any cart products' do
        expect { described_class.call(cart, product.id) }.not_to change(CartProduct, :count)
      end
    end

    context 'when product_id is from non-existent product' do
      it 'returns errors with status not_found' do
        result = described_class.call(cart, 99999)

        expect(result[:status]).to eq(:not_found)
        expect(result[:errors]).to include('Produto não encontrado no carrinho')
      end
    end

    context 'when product_id is passed as string' do
      let!(:cart_product) { create(:cart_product, cart: cart, product: product, quantity: 1) }

      it 'finds and removes the product' do
        result = described_class.call(cart, product.id.to_s)

        expect(result[:status]).to eq(:ok)
        expect(result[:cart].cart_products).not_to include(cart_product)
      end
    end

    context 'when removing unit by unit until empty' do
      let!(:cart_product) { create(:cart_product, cart: cart, product: product, quantity: 2) }

      it 'first call decrements to 1, second call removes entirely' do
        result1 = described_class.call(cart, product.id)
        expect(result1[:cart].cart_products.first.quantity).to eq(1)

        result2 = described_class.call(cart, product.id)
        expect(result2[:cart].cart_products).to be_empty
      end
    end
  end
end
