class DecksController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_deck, only: %i[show edit update destroy]

  def index
    @decks = Deck.all
  end

  def show
  end

  def new
    @deck = Deck.new
  end

  def create
    @deck = Deck.new(deck_params)

    if @deck.save
      redirect_to @deck, notice: 'Deck created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @deck.update(deck_params)
      redirect_to @deck, notice: 'Deck updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deck.destroy
    redirect_to decks_url, notice: 'Deck deleted successfully.'
  end

  private

  def set_deck
    @deck = Deck.find(params[:id])
  end

  def deck_params
    params.require(:deck).permit(:name, :description, :price, :status, :active)
  end
end
