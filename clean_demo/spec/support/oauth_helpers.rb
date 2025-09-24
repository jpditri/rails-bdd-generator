# frozen_string_literal: true

module OAuthHelpers
  def setup_oauth_test_environment
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new({
      provider: 'github',
      uid: '123456',
      info: {
        name: 'Test User',
        email: 'test@example.com'
      },
      credentials: {
        token: 'mock_token',
        expires_at: Time.now + 1.week
      }
    })
  end

  def cleanup_oauth_test_environment
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:default] = nil
  end

  def oauth_link_present?(provider)
    page.has_css?("a[href*='#{provider}']", wait: 0)
  end

  def simulate_successful_oauth_login(provider)
    OmniAuth.config.add_mock(provider.to_sym, {
      uid: '123456',
      info: {
        name: 'OAuth User',
        email: 'oauth@example.com'
      }
    })

    user = User.find_or_create_by!(email: 'oauth@example.com') do |u|
      u.name = 'OAuth User'
      u.provider = provider.to_s
      u.uid = '123456'
    end

    sign_in(user)
    user
  end

  def simulate_oauth_failure(provider, reason = :invalid_credentials)
    OmniAuth.config.mock_auth[provider.to_sym] = reason
  end
end
