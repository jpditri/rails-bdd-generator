class CardsController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_card, only: %i[show edit update destroy]

  def index
    @cards = Card.all
  end

  def show
  end

  def new
    @card = Card.new
  end

  def create
    @card = Card.new(card_params)

    if @card.save
      redirect_to @card, notice: 'Card created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @card.update(card_params)
      redirect_to @card, notice: 'Card updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @card.destroy
    redirect_to cards_url, notice: 'Card deleted successfully.'
  end

  private

  def set_card
    @card = Card.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:name, :description, :price, :status, :active)
  end
end
