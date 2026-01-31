# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Products API', type: :request do
  path '/products' do
    get 'Lista todos os produtos' do
      tags 'Produtos'
      produces 'application/json'

      response '200', 'lista de produtos' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
        end
      end
    end

    post 'Cria um produto' do
      tags 'Produtos'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :product, in: :body, schema: {
        type: :object,
        properties: {
          product: {
            type: :object,
            properties: {
              name: { type: :string },
              price: { type: :number }
            },
            required: %w[name price]
          }
        },
        required: ['product']
      }

      response '201', 'produto criado' do
        let(:request_params) { { product: { name: 'Produto Teste', price: 9.99 } } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to include('id', 'name', 'price')
          expect(data['name']).to eq('Produto Teste')
        end
      end

      response '422', 'requisição inválida' do
        let(:request_params) { { product: { name: '', price: -1 } } }
        run_test!
      end
    end
  end

  path '/products/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'ID do produto'

    get 'Retorna um produto' do
      tags 'Produtos'
      produces 'application/json'

      response '200', 'produto encontrado' do
        let(:product) { create(:product, name: 'Produto A', price: 10.0) }
        let(:id) { product.id }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(product.id)
          expect(data['name']).to eq('Produto A')
        end
      end

      response '404', 'produto não encontrado' do
        let(:id) { 99_999 }
        run_test!
      end
    end

    patch 'Atualiza um produto' do
      tags 'Produtos'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :product, in: :body, schema: {
        type: :object,
        properties: {
          product: {
            type: :object,
            properties: {
              name: { type: :string },
              price: { type: :number }
            }
          }
        }
      }

      response '200', 'produto atualizado' do
        let(:product_record) { create(:product, name: 'Antigo', price: 5.0) }
        let(:id) { product_record.id }
        let(:request_params) { { product: { name: 'Atualizado', price: 15.0 } } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq('Atualizado')
          expect(data['price'].to_f).to eq(15.0)
        end
      end

      response '422', 'requisição inválida' do
        let(:product_record) { create(:product) }
        let(:id) { product_record.id }
        let(:request_params) { { product: { price: -1 } } }
        run_test!
      end
    end

    delete 'Remove um produto' do
      tags 'Produtos'

      response '204', 'produto removido' do
        let(:product) { create(:product) }
        let(:id) { product.id }
        run_test!
      end

      response '404', 'produto não encontrado' do
        let(:id) { 99_999 }
        run_test!
      end
    end
  end
end
