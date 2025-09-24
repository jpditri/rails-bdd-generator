require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:user) { create(:user, user: user) }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns success' do
      get :show, params: { id: user.id }
      expect(response).to be_successful
    end
  end
end
