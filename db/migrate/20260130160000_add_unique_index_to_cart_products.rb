class AddUniqueIndexToCartProducts < ActiveRecord::Migration[7.1]
  def change
    add_index :cart_products, [:cart_id, :product_id], unique: true
  end
end
