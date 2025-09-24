# frozen_string_literal: true

module ApiHelpers
  def json_response
    @json_response ||= JSON.parse(response.body, symbolize_names: true)
  end

  def auth_headers(user)
    {
      'Authorization' => "Bearer #{user.api_token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def paginated_response?
    json_response.key?(:meta) && json_response[:meta].key?(:current_page)
  end

  def expect_paginated_response(total:, per_page: 20)
    expect(paginated_response?).to be true
    expect(json_response[:meta][:total]).to eq(total)
    expect(json_response[:meta][:per_page]).to eq(per_page)
  end

  def expect_error_response(status:, message: nil)
    expect(response).to have_http_status(status)
    expect(json_response[:errors]).to be_present

    if message
      expect(json_response[:errors]).to include(message)
    end
  end
end
