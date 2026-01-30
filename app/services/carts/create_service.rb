module Carts
  class CreateService
    def self.call(params)
      errors = []

      ActiveRecord::Base.transaction do
        @cart = Cart.create!
        @cart_product = CartProducts::CreateService.call(@cart, params)
        @cart.update!(total_price: @cart_product.total_price)
      end

      return { cart: @cart, cart_product: @cart_product, errors: errors, status: :created }
    rescue ActiveRecord::RecordNotFound => e
      return { errors: [e.message], status: :not_found }
    rescue ActiveRecord::RecordInvalid, CartProducts::CreateService::MissingParameterError => e
      return { errors: [e.message], status: :unprocessable_entity }
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error(e.message)
      return { errors: [e.message], status: :internal_server_error }
    rescue => e
      Rails.logger.error(e.message)
      return { errors: [e.message], status: :internal_server_error }
    end
  end
end