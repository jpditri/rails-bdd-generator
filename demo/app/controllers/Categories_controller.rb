class CategoriesController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_Category, only: %i[show edit update destroy]

  def index
    @Categories = Category.all
  end

  def show
  end

  def new
    @Category = Category.new
  end

  def create
    @Category = Category.new(Category_params)

    if @Category.save
      redirect_to @Category, notice: 'Category created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @Category.update(Category_params)
      redirect_to @Category, notice: 'Category updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @Category.destroy
    redirect_to Categories_url, notice: 'Category deleted successfully.'
  end

  private

  def set_Category
    @Category = Category.find(params[:id])
  end

  def Category_params
    params.require(:Category).permit(:name, :description)
  end
end
