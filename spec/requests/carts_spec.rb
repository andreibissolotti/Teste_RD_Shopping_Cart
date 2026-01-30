require 'rails_helper'

RSpec.describe "/carts", type: :request do
  describe "POST /carts" do
    let(:product) { create(:product, name: "Produto Teste", price: 1.99) }

    context 'when parameters are valid' do
      before do
        post '/carts', params: { product_id: product.id, quantity: 2 }, as: :json
      end

      it 'returns status 201' do
        expect(response).to have_http_status(:created)
      end

      it 'returns cart with expected structure' do
        json = response.parsed_body
        expect(json).to include('id', 'products', 'total_price')
        expect(json['products']).to be_an(Array)
        expect(json['products'].size).to eq(1)
      end

      it 'returns product with expected fields' do
        json = response.parsed_body
        product_data = json['products'].first
        expect(product_data).to include('id', 'name', 'quantity', 'unit_price', 'total_price')
        expect(product_data['id']).to eq(product.id)
        expect(product_data['name']).to eq('Produto Teste')
        expect(product_data['quantity']).to eq(2)
        expect(product_data['unit_price']).to eq(1.99)
        expect(product_data['total_price']).to eq(3.98)
      end

      it 'returns correct total_price' do
        json = response.parsed_body
        expect(json['total_price']).to eq(3.98)
      end
    end

    context 'when product does not exist' do
      before do
        post '/carts', params: { product_id: 99999, quantity: 1 }, as: :json
      end

      it 'returns status 404' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns errors in response' do
        json = response.parsed_body
        expect(json['errors']).to be_present
        expect(json['errors'].first).to match(/Couldn't find Product|Record not found/i)
      end
    end

    context 'when params are missing' do
      before do
        post '/carts', params: { quantity: 1 }, as: :json
      end

      it 'returns status 422' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors indicating missing product_id' do
        json = response.parsed_body
        expect(json['errors']).to include('Parâmetro: product_id é obrigatório')
      end
    end

    context 'when quantity is invalid' do
      before do
        post '/carts', params: { product_id: product.id, quantity: -1 }, as: :json
      end

      it 'returns status 422' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors in response' do
        json = response.parsed_body
        expect(json['errors']).to be_present
      end
    end
  end

  describe "POST /add_items" do
    let(:cart) { Cart.create }
    let(:product) { Product.create(name: "Test Product", price: 10.0) }
    let!(:cart_item) { CartItem.create(cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      subject do
        post '/carts/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/carts/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end
    end
  end
end
