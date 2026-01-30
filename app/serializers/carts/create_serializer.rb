module Carts
  class CreateSerializer < CartBaseSerializer
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
      {
        status: 201,
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
