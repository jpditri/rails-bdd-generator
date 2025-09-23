Rails.application.routes.draw do
  # Rails 8 built-in authentication routes
  resource :session
  resources :passwords, param: :token

  root 'home#index'

  resources :Books
  resources :Authors
  resources :Categories

  namespace :api do
    namespace :v1 do
      resources :users
      resources :Books
      resources :Authors
      resources :Categories
    end
  end
end
