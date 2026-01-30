module Carts
  class CreateSerializer
    def self.call(result)
      new.call(result)
    end

    def call(result)
      if result[:status] == :created
        success_response(result)
      else
        error_response(result)
      end
    end

    private

    def success_response(result)
      cart = result[:cart]
      products = cart.cart_products.includes(:product).map do |cart_product|
        {
          id: cart_product.product.id,
          name: cart_product.product.name,
          quantity: cart_product.quantity,
          unit_price: cart_product.product.price.to_f,
          total_price: cart_product.total_price.to_f
        }
      end

      {
        status: 201,
        body: {
          id: cart.id,
          products: products,
          total_price: cart.total_price.to_f
        }
      }
    end

    def error_response(result)
      status_code = case result[:status]
                    when :not_found then 404
                    when :unprocessable_entity then 422
                    else 500
                    end

      {
        status: status_code,
        body: { errors: result[:errors] }
      }
    end
  end
end
