class BooksController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_Book, only: %i[show edit update destroy]

  def index
    @Books = Book.all
  end

  def show
  end

  def new
    @Book = Book.new
  end

  def create
    @Book = Book.new(Book_params)

    if @Book.save
      redirect_to @Book, notice: 'Book created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @Book.update(Book_params)
      redirect_to @Book, notice: 'Book updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @Book.destroy
    redirect_to Books_url, notice: 'Book deleted successfully.'
  end

  private

  def set_Book
    @Book = Book.find(params[:id])
  end

  def Book_params
    params.require(:Book).permit(:title, :description, :isbn, :publication_date, :price, :stock_quantity)
  end
end
