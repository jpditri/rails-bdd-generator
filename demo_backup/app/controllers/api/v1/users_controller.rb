module Api
  module V1
    class UsersController < Api::V1::BaseController
      before_action :set_user, only: %i[show update destroy]

      def index
        @users = current_user.users.page(params[:page])
        render json: @users
      end

      def show
        render json: @user
      end

      def create
        @user = current_user.users.build(user_params)

        if @user.save
          render json: @user, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_params)
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @user.destroy
        head :no_content
      end

      private

      def set_user
        @user = current_user.users.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:email, :first_name, :last_name, :role)
      end
    end
  end
end
