module Api
  module V1
    class OrdersController < Api::V1::BaseController
      before_action :set_order, only: %i[show update destroy]

      def index
        @orders = current_user.orders.page(params[:page])
        render json: @orders
      end

      def show
        render json: @order
      end

      def create
        @order = current_user.orders.build(order_params)

        if @order.save
          render json: @order, status: :created
        else
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @order.update(order_params)
          render json: @order
        else
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @order.destroy
        head :no_content
      end

      private

      def set_order
        @order = current_user.orders.find(params[:id])
      end

      def order_params
        params.require(:order).permit(:order_number, :total_amount, :status, :shipping_address, :payment_method, :notes, :shipped_at)
      end
    end
  end
end
