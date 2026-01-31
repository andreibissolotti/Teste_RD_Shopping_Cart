require 'rails_helper'

RSpec.describe "/cart", type: :request do
  describe "GET /cart" do
    context 'when cart exists in session' do
      let(:product) { create(:product, name: "Produto A", price: 10.0) }

      before do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        get '/cart'
      end

      it 'returns status 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns cart with expected structure' do
        json = response.parsed_body
        expect(json).to include('id', 'products', 'total_price')
        expect(json['products'].size).to eq(1)
        expect(json['total_price']).to eq(20.0)
      end
    end

    context 'when no cart in session' do
      before { get '/cart' }

      it 'returns status 404' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error message' do
        json = response.parsed_body
        expect(json['errors']).to include('Carrinho não encontrado')
      end
    end
  end

  describe "POST /cart" do
    let(:product) { create(:product, name: "Produto Teste", price: 1.99) }

    context 'when parameters are valid' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
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
        post '/cart', params: { product_id: 99999, quantity: 1 }, as: :json
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
        post '/cart', params: { quantity: 1 }, as: :json
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
        post '/cart', params: { product_id: product.id, quantity: -1 }, as: :json
      end

      it 'returns status 422' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors in response' do
        json = response.parsed_body
        expect(json['errors']).to be_present
      end
    end

    context 'when adding second product to same cart (session reuse)' do
      let(:product_b) { create(:product, name: "Produto B", price: 5.0) }

      before do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        post '/cart', params: { product_id: product_b.id, quantity: 1 }, as: :json
      end

      it 'returns status 201' do
        expect(response).to have_http_status(:created)
      end

      it 'returns cart with two products' do
        json = response.parsed_body
        expect(json['products'].size).to eq(2)
        expect(json['total_price']).to eq(8.98) # 2*1.99 + 1*5.0
      end
    end
  end

  describe "POST /cart/add_item" do
    let(:product) { create(:product, name: "Test Product", price: 10.0) }

    context 'when cart exists in session' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_item', params: { product_id: product.id, quantity: 2 }, as: :json
      end

      it 'returns status 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates quantity of existing product in cart' do
        json = response.parsed_body
        expect(json['products'].size).to eq(1)
        expect(json['products'].first['quantity']).to eq(3)
        expect(json['total_price']).to eq(30.0)
      end
    end

    context 'when no cart in session' do
      before do
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'returns status 404' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error message' do
        json = response.parsed_body
        expect(json['errors']).to include('Carrinho não encontrado')
      end
    end

    context 'when params are missing' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_item', params: { quantity: 1 }, as: :json
      end

      it 'returns status 422' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors' do
        json = response.parsed_body
        expect(json['errors']).to be_present
      end
    end
  end

  describe "DELETE /cart/:product_id" do
    let(:product) { create(:product, name: "Produto X", price: 15.0) }

    context 'when cart exists and product is in cart' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        delete "/cart/#{product.id}"
      end

      it 'returns status 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'removes one unit (unitary removal by default)' do
        json = response.parsed_body
        expect(json['products'].size).to eq(1)
        expect(json['products'].first['quantity']).to eq(1)
        expect(json['total_price']).to eq(15.0)
      end
    end

    context 'when removing last unit (cart becomes empty)' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        delete "/cart/#{product.id}"
      end

      it 'returns status 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns cart with empty products' do
        json = response.parsed_body
        expect(json['products']).to eq([])
        expect(json['total_price']).to eq(0)
      end
    end

    context 'when product not in cart' do
      let(:other_product) { create(:product, name: "Outro", price: 5.0) }

      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        delete "/cart/#{other_product.id}"
      end

      it 'returns status 404' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error message' do
        json = response.parsed_body
        expect(json['errors']).to include('Produto não encontrado no carrinho')
      end
    end

    context 'when no cart in session' do
      before { delete "/cart/#{product.id}" }

      it 'returns status 404' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns cart not found error' do
        json = response.parsed_body
        expect(json['errors']).to include('Carrinho não encontrado')
      end
    end

    context 'when remove_all is true' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 3 }, as: :json
        delete "/cart/#{product.id}?remove_all=true"
      end

      it 'returns status 200 with empty products' do
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['products']).to eq([])
        expect(json['total_price']).to eq(0)
      end
    end
  end
end
