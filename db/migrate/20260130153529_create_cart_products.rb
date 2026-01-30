class CreateCartProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :cart_products do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.timestamps
    end
  end
end
