module Carts
  class CartBaseSerializer
    def serialize_cart(cart)
      products = serialize_cart_product_collection(cart.cart_products.includes(:product))

      {
        id: cart.id,
        products: products,
        total_price: cart.total_price.to_f
      }
    end

    def serialize_cart_product(cart_product)
      {
        id: cart_product.product.id,
        name: cart_product.product.name,
        quantity: cart_product.quantity,
        unit_price: cart_product.product.price.to_f,
        total_price: cart_product.total_price.to_f
      }
    end

    def serialize_cart_product_collection(cart_products)
      return [] if cart_products.blank?

      cart_products.map { |cart_product| serialize_cart_product(cart_product) }
    end
  end
end
