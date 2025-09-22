Rails.application.routes.draw do
  # Rails 8 built-in authentication routes
  resource :session
  resources :passwords, param: :token

  root 'home#index'

  resources :books
  resources :orders
  resources :order_items
  resources :reviews

  namespace :api do
    namespace :v1 do
      resources :users
      resources :books
      resources :orders
      resources :order_items
      resources :reviews
    end
  end
end
