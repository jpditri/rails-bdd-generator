Rails.application.routes.draw do
  # Rails 8 built-in authentication routes
  resource :session
  resources :passwords, param: :token

  root 'home#index'

  resources :cards
  resources :decks
  resources :players
  resources :games

  namespace :api do
    namespace :v1 do
      resources :users
      resources :cards
      resources :decks
      resources :players
      resources :games
    end
  end
end
