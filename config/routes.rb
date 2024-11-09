Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  resources :sessions, only: [:index]
  resources :profiles, only: [:show, :update]

  resources :pair_requests, only: [:index] do
    scope module: 'pair_requests' do
      resources :offers, only: [:index, :new, :create] do
        post "accept", on: :member
      end
    end

    get :search, on: :collection
  end

  namespace :users do
    resources :pair_requests
    resources :offers, only: [:index]
  end
end
