class CartsController < ApplicationController
  before_action :set_cart, only: [:show, :destroy]

  def index
  end

  def show
  end

  def create
    result = Carts::CreateService.call(current_cart, create_cart_params)
    response = Carts::CreateSerializer.call(result)

    session[:cart_id] = result[:cart].id if result[:status] == :created
    render json: response[:body], status: response[:status]
  end

  def add_item
  end

  def destroy
  end

  private

  def current_cart
    return nil unless session[:cart_id].present?
    Cart.find_by(id: session[:cart_id])
  end

  def create_cart_params
    params.permit(:product_id, :quantity)
  end
end
