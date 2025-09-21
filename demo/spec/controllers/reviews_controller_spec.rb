require 'rails_helper'

RSpec.describe ReviewsController, type: :controller do
  let(:user) { create(:user) }
  let(:review) { create(:review, user: user) }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns success' do
      get :show, params: { id: review.id }
      expect(response).to be_successful
    end
  end
end
