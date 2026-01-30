require 'rails_helper'

RSpec.describe Carts::CreateService do
  let(:product) { create(:product, price: 25.0) }
  let(:valid_params) { { product_id: product.id, quantity: 2 } }

  describe '.call' do
    context 'when all parameters are valid' do
      it 'creates a cart' do
        expect {
          described_class.call(valid_params)
        }.to change(Cart, :count).by(1)
      end

      it 'creates a cart product associated to the new cart' do
        result = described_class.call(valid_params)

        expect(result[:cart_product]).to be_a(CartProduct)
        expect(result[:cart_product].cart).to eq(result[:cart])
        expect(result[:cart_product].product).to eq(product)
        expect(result[:cart_product].quantity).to eq(2)
      end

      it 'updates cart total_price with cart_product total_price' do
        result = described_class.call(valid_params)

        expect(result[:cart].total_price).to eq(product.price * valid_params[:quantity])
        expect(result[:cart].total_price).to eq(result[:cart_product].total_price)
      end

      it 'returns hash with cart, cart_product and empty errors' do
        result = described_class.call(valid_params)

        expect(result).to include(:cart, :cart_product, :errors)
        expect(result[:cart]).to be_a(Cart)
        expect(result[:cart]).to be_persisted
        expect(result[:errors]).to eq([])
      end
    end

    context 'when params is nil' do
      it 'does not create a cart' do
        expect { described_class.call(nil) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors' do
        result = described_class.call(nil)
        expect(result).to eq(errors: ['Parâmetro: params é obrigatório'])
      end
    end

    context 'when product_id is missing' do
      let(:invalid_params) { { quantity: 1 } }

      it 'does not create a cart' do
        expect { described_class.call(invalid_params) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors' do
        result = described_class.call(invalid_params)
        expect(result[:errors]).to include('Parâmetro: product_id é obrigatório')
      end
    end

    context 'when quantity is missing' do
      let(:invalid_params) { { product_id: product.id } }

      it 'does not create a cart' do
        expect { described_class.call(invalid_params) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors' do
        result = described_class.call(invalid_params)
        expect(result[:errors]).to include('Parâmetro: quantity é obrigatório')
      end
    end

    context 'when product does not exist' do
      let(:invalid_params) { { product_id: 99999, quantity: 1 } }

      it 'does not create a cart' do
        expect { described_class.call(invalid_params) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors' do
        result = described_class.call(invalid_params)
        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first).to match(/Record not found|Couldn't find Product/i)
      end
    end

    context 'when quantity is invalid (e.g. zero or negative)' do
      let(:invalid_params) { { product_id: product.id, quantity: -1 } }

      it 'does not create a cart' do
        expect { described_class.call(invalid_params) }.not_to change(Cart, :count)
      end

      it 'returns hash with errors' do
        result = described_class.call(invalid_params)
        expect(result[:errors]).not_to be_empty
      end
    end
  end
end
