class AuthorsController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_Author, only: %i[show edit update destroy]

  def index
    @Authors = Author.all
  end

  def show
  end

  def new
    @Author = Author.new
  end

  def create
    @Author = Author.new(Author_params)

    if @Author.save
      redirect_to @Author, notice: 'Author created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @Author.update(Author_params)
      redirect_to @Author, notice: 'Author updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @Author.destroy
    redirect_to Authors_url, notice: 'Author deleted successfully.'
  end

  private

  def set_Author
    @Author = Author.find(params[:id])
  end

  def Author_params
    params.require(:Author).permit(:first_name, :last_name, :bio)
  end
end
