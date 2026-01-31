# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Cart API', type: :request do
  path '/cart' do
    get 'Lista itens do carrinho atual' do
      tags 'Carrinho'
      produces 'application/json'
      description 'Retorna o carrinho vinculado à sessão. Requer cookie de sessão com carrinho criado.'

      response '200', 'carrinho encontrado' do
        let(:product) { create(:product, name: 'Produto A', price: 10.0) }
        before do
          post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to include('id', 'products', 'total_price')
          expect(data['products']).to be_an(Array)
          expect(data['products'].first).to include('id', 'name', 'quantity', 'unit_price', 'total_price')
        end
      end

      response '404', 'carrinho não encontrado' do
        run_test!
      end
    end

    post 'Cria carrinho ou adiciona produto ao carrinho' do
      tags 'Carrinho'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :cart_params, in: :body, schema: {
        type: :object,
        properties: {
          product_id: { type: :integer, description: 'ID do produto' },
          quantity: { type: :integer, description: 'Quantidade' }
        },
        required: %w[product_id quantity]
      }

      response '201', 'carrinho criado ou produto adicionado' do
        let(:product) { create(:product, name: 'Produto Teste', price: 1.99) }
        let(:request_params) { { product_id: product.id, quantity: 2 } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to include('id', 'products', 'total_price')
          expect(data['products'].size).to eq(1)
          expect(data['total_price']).to eq(3.98)
        end
      end

      response '404', 'produto não encontrado' do
        let(:request_params) { { product_id: 99_999, quantity: 1 } }
        run_test!
      end

      response '422', 'parâmetros inválidos' do
        let(:request_params) { { quantity: 1 } }
        run_test!
      end
    end
  end

  path '/cart/add_item' do
    post 'Adiciona ou atualiza quantidade de produto no carrinho' do
      tags 'Carrinho'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :add_item_params, in: :body, schema: {
        type: :object,
        properties: {
          product_id: { type: :integer },
          quantity: { type: :integer }
        },
        required: %w[product_id quantity]
      }

      response '200', 'item adicionado ou quantidade atualizada' do
        let(:product) { create(:product, name: 'Produto X', price: 10.0) }
        let(:request_params) { { product_id: product.id, quantity: 2 } }
        before do
          post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['products'].first['quantity']).to eq(3)
          expect(data['total_price']).to eq(30.0)
        end
      end

      response '404', 'carrinho não encontrado' do
        let(:product) { create(:product) }
        let(:request_params) { { product_id: product.id, quantity: 1 } }
        run_test!
      end
    end
  end

  path '/cart/{product_id}' do
    parameter name: :product_id, in: :path, type: :integer, description: 'ID do produto a remover'
    parameter name: :remove_all, in: :query, type: :boolean, required: false,
              description: 'Se true, remove todas as unidades do produto'

    delete 'Remove produto do carrinho' do
      tags 'Carrinho'
      produces 'application/json'

      response '200', 'uma unidade removida (padrão)' do
        let(:product) { create(:product, name: 'Produto Y', price: 15.0) }
        let(:product_id) { product.id }
        before do
          post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['products'].first['quantity']).to eq(1)
          expect(data['total_price']).to eq(15.0)
        end
      end

      response '200', 'todas as unidades removidas com remove_all=true' do
        let(:product) { create(:product) }
        let(:product_id) { product.id }
        let(:remove_all) { true }
        before do
          post '/cart', params: { product_id: product.id, quantity: 3 }, as: :json
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['products']).to eq([])
          expect(data['total_price']).to eq(0)
        end
      end

      response '404', 'carrinho ou produto não encontrado' do
        let(:product_id) { 99_999 }
        run_test!
      end
    end
  end
end
