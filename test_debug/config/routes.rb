Rails.application.routes.draw do
  # Rails 8 built-in authentication routes
  resource :session
  resources :passwords, param: :token

  root 'home#index'

  

  namespace :api do
    namespace :v1 do
      resources :users
    end
  end
end
