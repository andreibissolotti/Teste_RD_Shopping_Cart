class CartsController < ApplicationController
  def show
    return render_cart_not_found unless current_cart

    body = Carts::CartBaseSerializer.new.serialize_cart(current_cart)
    render json: body, status: :ok
  end

  def create
    result = Carts::CreateService.call(current_cart, create_cart_params)
    response = Carts::CreateSerializer.call(result)

    session[:cart_id] = result[:cart].id if result[:status] == :created
    render json: response[:body], status: response[:status]
  end

  def add_item
    return render_cart_not_found unless current_cart

    result = CartProducts::AddOrUpdateService.call(current_cart, add_item_params)
    response = Carts::CartResultSerializer.call(result)
    render json: response[:body], status: response[:status]
  end

  def remove_product
    return render_cart_not_found unless current_cart

    result = Carts::RemoveProductService.call(
      current_cart,
      params[:product_id],
      remove_all: ActiveModel::Type::Boolean.new.cast(params[:remove_all])
    )
    response = Carts::CartResultSerializer.call(result)
    render json: response[:body], status: response[:status]
  end

  private

  def current_cart
    return nil unless session[:cart_id].present?
    Cart.find_by(id: session[:cart_id])
  end

  def create_cart_params
    params.permit(:product_id, :quantity)
  end

  def add_item_params
    params.permit(:product_id, :quantity)
  end

  def render_cart_not_found
    render json: { errors: ['Carrinho não encontrado'] }, status: :not_found
  end
end
