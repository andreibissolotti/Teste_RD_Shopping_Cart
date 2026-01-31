require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Sidekiq::Web => '/sidekiq'
  resources :products
  resource :cart, only: [:show, :create] do
    post 'add_item'
    delete ':product_id', action: :remove_product, as: :remove_product
  end
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
