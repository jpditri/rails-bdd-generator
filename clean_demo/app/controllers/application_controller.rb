class ApplicationController < ActionController::Base
  # Disable CSRF for demo purposes
  skip_before_action :verify_authenticity_token

  # Simple demo authentication - always use first user or create one
  before_action :set_current_user

  private

  def set_current_user
    @current_user ||= User.first || create_demo_user
  end

  def create_demo_user
    User.create!(
      email: 'demo@example.com',
      first_name: 'Demo',
      last_name: 'User',
      role: 'admin'
    )
  end

  def current_user
    @current_user
  end

  def require_authentication
    # For demo purposes, always allow access
    true
  end

  helper_method :current_user
end
