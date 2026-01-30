module CartProducts
  class CreateService
    class MissingParameterError < StandardError
      def initialize(param_name)
        super("Parâmetro: #{param_name} é obrigatório")
      end
    end

    def self.call(cart, params)
      new.call(cart, params)
    end

    def call(cart, params)
      valid_params = validate_params(params)
      product = Product.find(valid_params[:product_id])
      cart_product = CartProduct.create!(cart: cart, product: product, quantity: valid_params[:quantity])
      return cart_product
    rescue => e
      Rails.logger.error(e.message)
      raise e
    end

    private

    def validate_params(params)
      raise MissingParameterError, "params" if params.blank?

      params = params.deep_symbolize_keys

      raise MissingParameterError, "quantity" if params[:quantity].blank?
      raise MissingParameterError, "product_id" if params[:product_id].blank?

      return params
    end
  end
end