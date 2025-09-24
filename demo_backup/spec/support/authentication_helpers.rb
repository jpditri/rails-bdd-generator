# frozen_string_literal: true

module AuthenticationHelpers
  def sign_in(user)
    if respond_to?(:visit)
      # Feature specs - simulate login through UI
      visit login_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'
    else
      # Controller specs - set session
      session[:user_id] = user.id
    end
  end

  def sign_out
    if respond_to?(:visit)
      click_link 'Sign Out'
    else
      session.delete(:user_id)
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
end
