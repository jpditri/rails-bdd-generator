require 'rails_helper'

RSpec.describe Order_itemsController, type: :controller do
  let(:user) { create(:user) }
  let(:order_item) { create(:order_item, user: user) }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns success' do
      get :show, params: { id: order_item.id }
      expect(response).to be_successful
    end
  end
end
