module Carts
  class CreateService
    def self.call(cart_or_nil, params)
      new.call(cart_or_nil, params)
    end

    def call(cart_or_nil, params)
      if cart_or_nil.present?
        add_to_cart(cart_or_nil, params)
      else
        create_cart_and_add(params)
      end
    end

    private

    def add_to_cart(cart, params)
      result = CartProducts::AddOrUpdateService.call(cart, params)
      result[:status] == :ok ? success_result(result) : result
    end

    def create_cart_and_add(params)
      result = nil
      cart = nil

      ActiveRecord::Base.transaction do
        cart = Cart.create!
        result = CartProducts::AddOrUpdateService.call(cart, params)
        raise ActiveRecord::Rollback if result[:status] != :ok
      end

      result[:status] == :ok ? success_result(result) : result
    end

    def success_result(result)
      { cart: result[:cart], cart_product: result[:cart_product], errors: [], status: :created }
    end
  end
end