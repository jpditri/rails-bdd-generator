module Api
  module V1
    class ReviewsController < Api::V1::BaseController
      before_action :set_review, only: %i[show update destroy]

      def index
        @reviews = current_user.reviews.page(params[:page])
        render json: @reviews
      end

      def show
        render json: @review
      end

      def create
        @review = current_user.reviews.build(review_params)

        if @review.save
          render json: @review, status: :created
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @review.update(review_params)
          render json: @review
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @review.destroy
        head :no_content
      end

      private

      def set_review
        @review = current_user.reviews.find(params[:id])
      end

      def review_params
        params.require(:review).permit(:rating, :title, :content, :verified_purchase)
      end
    end
  end
end
