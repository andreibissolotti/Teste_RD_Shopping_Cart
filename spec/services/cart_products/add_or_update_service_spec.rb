require 'rails_helper'

RSpec.describe CartProducts::AddOrUpdateService do
  let(:cart) { create(:cart) }
  let(:product) { create(:product, price: 10.0) }
  let(:valid_params) { { product_id: product.id, quantity: 2 } }

  describe '.call' do
    context 'when product is not in cart' do
      it 'creates a new cart product' do
        expect {
          described_class.call(cart, valid_params)
        }.to change(CartProduct, :count).by(1)
      end

      it 'returns cart and cart_product with status ok' do
        result = described_class.call(cart, valid_params)

        expect(result[:status]).to eq(:ok)
        expect(result[:cart_product]).to be_a(CartProduct)
        expect(result[:cart_product].cart).to eq(cart)
        expect(result[:cart_product].product).to eq(product)
        expect(result[:cart_product].quantity).to eq(2)
      end

      it 'updates cart total_price' do
        result = described_class.call(cart, valid_params)

        expect(result[:cart].total_price).to eq(20.0)
      end
    end

    context 'when product already exists in cart' do
      let!(:cart_product) { create(:cart_product, cart: cart, product: product, quantity: 3) }

      it 'does not create a new cart product' do
        expect {
          described_class.call(cart, valid_params)
        }.not_to change(CartProduct, :count)
      end

      it 'updates the quantity by adding to existing' do
        result = described_class.call(cart, valid_params)

        expect(result[:cart_product].quantity).to eq(5)
        expect(cart_product.reload.quantity).to eq(5)
      end

      it 'recalculates cart total_price' do
        result = described_class.call(cart, valid_params)

        expect(result[:cart].total_price).to eq(50.0)
      end

      it 'returns status ok' do
        result = described_class.call(cart, valid_params)

        expect(result[:status]).to eq(:ok)
      end
    end

    context 'when product_id is missing' do
      let(:invalid_params) { { quantity: 1 } }

      it 'returns errors with status unprocessable_entity' do
        result = described_class.call(cart, invalid_params)

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:errors]).to include('Parâmetro: product_id é obrigatório')
      end

      it 'does not create or update cart products' do
        expect { described_class.call(cart, invalid_params) }.not_to change(CartProduct, :count)
      end
    end

    context 'when quantity is missing' do
      let(:invalid_params) { { product_id: product.id } }

      it 'returns errors with status unprocessable_entity' do
        result = described_class.call(cart, invalid_params)

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:errors]).to include('Parâmetro: quantity é obrigatório')
      end
    end

    context 'when params is nil' do
      it 'returns errors with status unprocessable_entity' do
        result = described_class.call(cart, nil)

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:errors]).to include('Parâmetro: params é obrigatório')
      end
    end

    context 'when product does not exist' do
      let(:invalid_params) { { product_id: 99999, quantity: 1 } }

      it 'returns errors with status not_found' do
        result = described_class.call(cart, invalid_params)

        expect(result[:status]).to eq(:not_found)
        expect(result[:errors].first).to match(/Couldn't find Product|Record not found/i)
      end

      it 'does not create cart products' do
        expect { described_class.call(cart, invalid_params) }.not_to change(CartProduct, :count)
      end
    end

    context 'when quantity is invalid (zero or negative)' do
      let(:invalid_params) { { product_id: product.id, quantity: -1 } }

      it 'returns errors with status unprocessable_entity' do
        result = described_class.call(cart, invalid_params)

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:errors]).not_to be_empty
      end
    end

    context 'with quantity as string' do
      it 'parses and adds quantity correctly' do
        create(:cart_product, cart: cart, product: product, quantity: 1)
        params = { product_id: product.id, quantity: '3' }

        result = described_class.call(cart, params)

        expect(result[:cart_product].quantity).to eq(4)
      end
    end
  end
end
