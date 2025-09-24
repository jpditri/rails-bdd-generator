module Api
  module V1
    class BaseController < ApplicationController
      # Base controller for API endpoints
      before_action :set_current_user

      # Skip CSRF protection for API endpoints (if available)
      skip_before_action :verify_authenticity_token, raise: false

      private

      def set_current_user
        # Simple demo authentication - always use first user or create one
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
    end
  end
end
