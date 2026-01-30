class CartsController < ApplicationController
  before_action :set_cart, only: [:show, :destroy]

  def index
  end

  def show
  end

  def create
    result = Carts::CreateService.call(create_cart_params)
    response = Carts::CreateSerializer.call(result)

    render json: response[:body], status: response[:status]
  end

  def add_item
  end

  def destroy
  end

  private

  def create_cart_params
    params.permit(:product_id, :quantity)
  end
end
