module Carts
  class RemoveProductService
    def self.call(cart, product_id, remove_all: false)
      new.call(cart, product_id, remove_all: remove_all)
    end

    def call(cart, product_id, remove_all: false)
      cart_product = cart.cart_products.find_by(product_id: product_id)

      if cart_product.blank?
        return { errors: ['Produto não encontrado no carrinho'], status: :not_found }
      end

      ActiveRecord::Base.transaction do
        if remove_all
          cart_product.destroy!
        else
          cart_product.quantity -= 1
          if cart_product.quantity <= 0
            cart_product.destroy!
          else
            cart_product.save!
          end
        end
        recalculate_cart_total(cart)
      end

      { cart: cart.reload, status: :ok }
    rescue => e
      Rails.logger.error(e.message)
      { errors: [e.message], status: :internal_server_error }
    end

    private

    def recalculate_cart_total(cart)
      total = cart.cart_products.reload.sum { |cp| cp.total_price }
      cart.update!(total_price: total)
    end
  end
end
