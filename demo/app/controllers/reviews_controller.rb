class ReviewsController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_review, only: %i[show edit update destroy]

  def index
    @reviews = current_user.reviews.page(params[:page])
  end

  def show
  end

  def new
    @review = current_user.reviews.build
  end

  def create
    @review = current_user.reviews.build(review_params)

    if @review.save
      redirect_to @review, notice: 'Review created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @review.update(review_params)
      redirect_to @review, notice: 'Review updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to reviews_url, notice: 'Review deleted successfully.'
  end

  private

  def set_review
    @review = current_user.reviews.find(params[:id])
  end

  def review_params
    params.require(:review).permit(:rating, :title, :content, :verified_purchase)
  end
end
