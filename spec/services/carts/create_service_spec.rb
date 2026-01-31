require 'rails_helper'

RSpec.describe Carts::CreateService do
  let(:product) { create(:product, price: 25.0) }
  let(:valid_params) { { product_id: product.id, quantity: 2 } }

  describe '.call' do
    context 'when cart is nil (new cart)' do
      it 'creates a cart' do
        expect {
          described_class.call(nil, valid_params)
        }.to change(Cart, :count).by(1)
      end

      it 'creates a cart product associated to the new cart' do
        result = described_class.call(nil, valid_params)

        expect(result[:cart_product]).to be_a(CartProduct)
        expect(result[:cart_product].cart).to eq(result[:cart])
        expect(result[:cart_product].product).to eq(product)
        expect(result[:cart_product].quantity).to eq(2)
      end

      it 'updates cart total_price with cart_product total_price' do
        result = described_class.call(nil, valid_params)

        expect(result[:cart].total_price).to eq(product.price * valid_params[:quantity])
        expect(result[:cart].total_price).to eq(result[:cart_product].total_price)
      end

      it 'returns hash with cart, cart_product, empty errors and status' do
        result = described_class.call(nil, valid_params)

        expect(result).to include(:cart, :cart_product, :errors, :status)
        expect(result[:cart]).to be_a(Cart)
        expect(result[:cart]).to be_persisted
        expect(result[:errors]).to eq([])
        expect(result[:status]).to eq(:created)
      end
    end

    context 'when cart is present (existing cart)' do
      let!(:cart) { create(:cart) }

      it 'does not create a new cart' do
        expect { described_class.call(cart, valid_params) }.not_to change(Cart, :count)
      end

      it 'adds product to existing cart and returns status created' do
        result = described_class.call(cart, valid_params)

        expect(result[:status]).to eq(:created)
        expect(result[:cart]).to eq(cart)
        expect(result[:cart_product].cart).to eq(cart)
        expect(result[:cart_product].product).to eq(product)
        expect(result[:cart_product].quantity).to eq(2)
      end

      it 'updates cart total_price' do
        result = described_class.call(cart, valid_params)

        expect(result[:cart].total_price).to eq(50.0)
      end

      context 'when product already in cart' do
        before { create(:cart_product, cart: cart, product: product, quantity: 1) }

        it 'adds quantity to existing cart_product' do
          result = described_class.call(cart, valid_params)

          expect(result[:cart_product].quantity).to eq(3)
        end
      end
    end

    context 'when params is nil' do
      it 'does not create a cart' do
        expect { described_class.call(nil, nil) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors and status' do
        result = described_class.call(nil, nil)
        expect(result).to eq(errors: ['Parâmetro: params é obrigatório'], status: :unprocessable_entity)
      end
    end

    context 'when product_id is missing' do
      let(:invalid_params) { { quantity: 1 } }

      it 'does not create a cart' do
        expect { described_class.call(nil, invalid_params) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors and status' do
        result = described_class.call(nil, invalid_params)
        expect(result[:errors]).to include('Parâmetro: product_id é obrigatório')
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end

    context 'when quantity is missing' do
      let(:invalid_params) { { product_id: product.id } }

      it 'does not create a cart' do
        expect { described_class.call(nil, invalid_params) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors and status' do
        result = described_class.call(nil, invalid_params)
        expect(result[:errors]).to include('Parâmetro: quantity é obrigatório')
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end

    context 'when product does not exist' do
      let(:invalid_params) { { product_id: 99999, quantity: 1 } }

      it 'does not create a cart' do
        expect { described_class.call(nil, invalid_params) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors and status' do
        result = described_class.call(nil, invalid_params)
        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first).to match(/Record not found|Couldn't find Product/i)
        expect(result[:status]).to eq(:not_found)
      end
    end

    context 'when quantity is invalid (e.g. zero or negative)' do
      let(:invalid_params) { { product_id: product.id, quantity: -1 } }

      it 'does not create a cart' do
        expect { described_class.call(nil, invalid_params) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors and status' do
        result = described_class.call(nil, invalid_params)
        expect(result[:errors]).not_to be_empty
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end
  end
end
