require_relative 'errors'

module CartProducts
  class AddOrUpdateService
    def self.call(cart, params)
      new.call(cart, params)
    end

    def call(cart, params)
      valid_params = validate_params(params)
      product = Product.find(valid_params[:product_id])
      quantity = valid_params[:quantity].to_i

      cart_product = cart.cart_products.find_by(product_id: product.id)

      ActiveRecord::Base.transaction do
        if cart_product
          cart_product.quantity += quantity
          cart_product.save!
        else
          cart_product = CartProduct.create!(cart: cart, product: product, quantity: quantity)
        end

        recalculate_cart_total(cart)
      end

      { cart: cart, cart_product: cart_product, status: :ok }
    rescue ActiveRecord::RecordNotFound => e
      { errors: [e.message], status: :not_found }
    rescue ActiveRecord::RecordInvalid, MissingParameterError, QuantityInvalidError => e
      { errors: [e.message], status: :unprocessable_entity }
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error(e.message)
      { errors: [e.message], status: :internal_server_error }
    rescue => e
      Rails.logger.error(e.message)
      { errors: [e.message], status: :internal_server_error }
    end

    private

    def validate_params(params)
      raise MissingParameterError, "params" if params.blank?

      params = params.to_h.deep_symbolize_keys

      raise MissingParameterError, "quantity" if params[:quantity].blank?
      raise QuantityInvalidError if params[:quantity].to_i <= 0
      raise MissingParameterError, "product_id" if params[:product_id].blank?

      params
    end

    def recalculate_cart_total(cart)
      total = cart.cart_products.reload.sum { |cp| cp.total_price }
      cart.update!(total_price: total)
    end
  end
end
