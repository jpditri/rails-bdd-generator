# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "/api/v1/order_items", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { 'Authorization' => "Bearer #{user.api_token}" } }

  describe 'GET /api/v1/order_items' do
    let!(:order_items) { create_list(:order_item, 3) }

    it 'returns all order_items' do
      get api_v1_order_items_path, headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['order_items'].size).to eq(3)
    end

    it 'paginates results' do
      create_list(:order_item, 25)

      get api_v1_order_items_path, params: { page: 2, per_page: 10 }, headers: headers

      json = JSON.parse(response.body)
      expect(json['order_items'].size).to eq(10)
      expect(json['meta']['current_page']).to eq(2)
    end
  end

  describe 'POST /api/v1/order_items' do
    let(:valid_params) do
      { order_item: attributes_for(:order_item) }
    end

    let(:invalid_params) do
      { order_item: attributes_for(:order_item, :invalid) }
    end

    context 'with valid parameters' do
      it 'creates a new order_item' do
        expect {
          post api_v1_order_items_path, params: valid_params, headers: headers
        }.to change(Order_item, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'returns errors' do
        post api_v1_order_items_path, params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'authentication' do
    it 'returns unauthorized without token' do
      get api_v1_order_items_path

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
