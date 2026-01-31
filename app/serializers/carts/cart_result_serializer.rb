module Carts
  class CartResultSerializer < CartBaseSerializer
    def self.call(result)
      new.call(result)
    end

    def call(result)
      if result[:status] == :ok
        success_response(result)
      else
        error_response(result)
      end
    end

    private

    def success_response(result)
      {
        status: 200,
        body: serialize_cart(result[:cart])
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
