class GamesController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_game, only: %i[show edit update destroy]

  def index
    @games = Game.all
  end

  def show
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)

    if @game.save
      redirect_to @game, notice: 'Game created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @game.update(game_params)
      redirect_to @game, notice: 'Game updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @game.destroy
    redirect_to games_url, notice: 'Game deleted successfully.'
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:name, :description, :price, :status, :active)
  end
end
