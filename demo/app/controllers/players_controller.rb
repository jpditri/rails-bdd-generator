class PlayersController < ApplicationController
  before_action :require_authentication  # Rails 8 built-in auth
  before_action :set_player, only: %i[show edit update destroy]

  def index
    @players = Player.all
  end

  def show
  end

  def new
    @player = Player.new
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      redirect_to @player, notice: 'Player created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @player.update(player_params)
      redirect_to @player, notice: 'Player updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @player.destroy
    redirect_to players_url, notice: 'Player deleted successfully.'
  end

  private

  def set_player
    @player = Player.find(params[:id])
  end

  def player_params
    params.require(:player).permit(:name, :description, :price, :status, :active)
  end
end
