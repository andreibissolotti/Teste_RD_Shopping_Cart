module Carts
  class CreateService    
    def self.call(params)
      errors = []

      ActiveRecord::Base.transaction do
        @cart = Cart.create!
        @cart_product = CartProducts::CreateService.call(@cart, params)
        @cart.update!(total_price: @cart_product.total_price)
      end

      return { cart: @cart, cart_product: @cart_product, errors: errors }
    rescue => e
      errors << e.message
      return { errors: errors }
    end
  end
end