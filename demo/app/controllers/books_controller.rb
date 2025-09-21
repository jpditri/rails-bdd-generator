class BooksController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_book, only: %i[show edit update destroy]

  def index
    @books = current_user.books.page(params[:page])
  end

  def show
  end

  def new
    @book = current_user.books.build
  end

  def create
    @book = current_user.books.build(book_params)

    if @book.save
      redirect_to @book, notice: 'Book created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: 'Book updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_url, notice: 'Book deleted successfully.'
  end

  private

  def set_book
    @book = current_user.books.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:title, :author, :isbn, :description, :price, :stock_quantity, :published_at, :category, :active)
  end
end
