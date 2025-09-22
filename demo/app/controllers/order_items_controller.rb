class Order_itemsController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_order_item, only: %i[show edit update destroy]

  def index
    @order_items = Order_item.all
  end

  def show
  end

  def new
    @order_item = Order_item.new
  end

  def create
    @order_item = Order_item.new(order_item_params)

    if @order_item.save
      redirect_to @order_item, notice: 'Order_item created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @order_item.update(order_item_params)
      redirect_to @order_item, notice: 'Order_item updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order_item.destroy
    redirect_to order_items_url, notice: 'Order_item deleted successfully.'
  end

  private

  def set_order_item
    @order_item = Order_item.find(params[:id])
  end

  def order_item_params
    params.require(:order_item).permit(:quantity, :unit_price, :subtotal)
  end
end
