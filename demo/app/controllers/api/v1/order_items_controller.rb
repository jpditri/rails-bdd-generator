module Api
  module V1
    class Order_itemsController < Api::V1::BaseController
      before_action :set_order_item, only: %i[show update destroy]

      def index
        @order_items = current_user.order_items.page(params[:page])
        render json: @order_items
      end

      def show
        render json: @order_item
      end

      def create
        @order_item = current_user.order_items.build(order_item_params)

        if @order_item.save
          render json: @order_item, status: :created
        else
          render json: { errors: @order_item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @order_item.update(order_item_params)
          render json: @order_item
        else
          render json: { errors: @order_item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @order_item.destroy
        head :no_content
      end

      private

      def set_order_item
        @order_item = current_user.order_items.find(params[:id])
      end

      def order_item_params
        params.require(:order_item).permit(:quantity, :unit_price, :subtotal)
      end
    end
  end
end
