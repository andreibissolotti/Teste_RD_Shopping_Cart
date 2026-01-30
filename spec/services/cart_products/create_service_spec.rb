require 'rails_helper'

RSpec.describe CartProducts::CreateService do
  let(:cart) { create(:cart) }
  let(:product) { create(:product) }
  let(:valid_params) { { "product_id": product.id, "quantity": 2 } }

  describe '.call' do
    context 'when all parameters are valid' do
      it 'creates a cart product' do
        expect {
          described_class.call(cart, valid_params)
        }.to change(CartProduct, :count).by(1)
      end

      it 'associates the cart product with the correct cart' do
        cart_product = described_class.call(cart, valid_params)
        expect(cart_product.cart).to eq(cart)
      end

      it 'associates the cart product with the correct product' do
        cart_product = described_class.call(cart, valid_params)
        expect(cart_product.product).to eq(product)
      end

      it 'sets the correct quantity' do
        cart_product = described_class.call(cart, valid_params)
        expect(cart_product.quantity).to eq(2)
      end

      it 'returns a persisted cart product' do
        cart_product = described_class.call(cart, valid_params)
        expect(cart_product).to be_persisted
        expect(cart_product).to be_a(CartProduct)
      end
    end

    context 'with quantity as string' do
      it 'creates cart product successfully' do
        params = { product_id: product.id, quantity: '3' }
        cart_product = described_class.call(cart, params)
        expect(cart_product.quantity).to eq(3)
      end
    end

    context 'when product does not exist' do
      let(:invalid_params) { { product_id: 99999, quantity: 1 } }

      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.call(cart, invalid_params)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'logs the error message' do
        allow(Rails.logger).to receive(:error)
        begin
          described_class.call(cart, invalid_params)
        rescue ActiveRecord::RecordNotFound
        end
        expect(Rails.logger).to have_received(:error)
      end
    end

    context 'when product_id is missing' do
      let(:invalid_params) { { quantity: 1 } }

      it 'raises MissingParameterError with message indicating missing product_id' do
        expect {
          described_class.call(cart, invalid_params)
        }.to raise_error(CartProducts::CreateService::MissingParameterError, 'Parâmetro: product_id é obrigatório')
      end
    end

    context 'when quantity is missing' do
      let(:invalid_params) { { product_id: product.id } }

      it 'raises MissingParameterError with message indicating missing quantity' do
        expect {
          described_class.call(cart, invalid_params)
        }.to raise_error(CartProducts::CreateService::MissingParameterError, 'Parâmetro: quantity é obrigatório')
      end
    end

    context 'when quantity is invalid' do
      let(:invalid_params) { { product_id: product.id, quantity: -1 } }

      it 'raises ActiveRecord::RecordInvalid' do
        expect {
          described_class.call(cart, invalid_params)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'logs the validation error' do
        allow(Rails.logger).to receive(:error)
        begin
          described_class.call(cart, invalid_params)
        rescue ActiveRecord::RecordInvalid
        end
        expect(Rails.logger).to have_received(:error)
      end
    end

    context 'when quantity is zero' do
      let(:invalid_params) { { product_id: product.id, quantity: 0 } }

      it 'raises ActiveRecord::RecordInvalid' do
        expect {
          described_class.call(cart, invalid_params)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when cart is nil' do
      it 'raises ActiveRecord::RecordInvalid' do
        expect {
          described_class.call(nil, valid_params)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when params is nil' do
      it 'raises MissingParameterError with message indicating missing params' do
        expect {
          described_class.call(cart, nil)
        }.to raise_error(CartProducts::CreateService::MissingParameterError, 'Parâmetro: params é obrigatório')
      end
    end

    context 'when database constraints fail' do
      before do
        allow(CartProduct).to receive(:create!).and_raise(ActiveRecord::StatementInvalid.new("PG::CheckViolation"))
      end

      it 're-raises the exception' do
        expect {
          described_class.call(cart, valid_params)
        }.to raise_error(ActiveRecord::StatementInvalid)
      end

      it 'logs the database error' do
        allow(Rails.logger).to receive(:error)
        begin
          described_class.call(cart, valid_params)
        rescue ActiveRecord::StatementInvalid
        end
        expect(Rails.logger).to have_received(:error)
      end
    end
  end
end