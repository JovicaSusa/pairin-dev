Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  devise_for :users, controllers: { registrations: "users/registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  get "privacy" => "pages#privacy", as: :privacy
  get "terms" => "pages#terms", as: :terms
  get "account-suspended" => "pages#account_suspended", as: :account_suspended

  # One-time step for accounts with no date of birth.
  resource :date_of_birth, only: [:show, :update]

  resources :sessions, only: [:index, :update]
  resources :profiles, only: [:show, :update]

  # Weekly hours and timezone (PATCH /availability updates the timezone).
  resource :availability, only: [:show, :update] do
    resources :windows, only: [:create, :destroy], module: :availabilities
  end

  resources :pair_requests, only: [:index] do
    scope module: 'pair_requests' do
      resources :offers, only: [:index, :new, :create]
    end

    get :search, on: :collection
  end

  namespace :users do
    resources :pair_requests, except: [:edit, :update] do
      patch :add_call_link, on: :member
      patch :pause, on: :member
      patch :resume, on: :member
    end
  end

  resources :partners, only: [:index, :show, :update], controller: "partnerships"

  resources :conversations, only: [:index, :show] do
    post :not_a_match, on: :member
    post :block, on: :member
    post :report, on: :member
    post :propose, on: :member
    post :accept_proposal, on: :member
    post :decline_proposal, on: :member
    resources :messages, only: [:create], module: :conversations
  end

  resources :activities, only: [:index]

  # Emails sent before replies needed sign-in linked here.
  get "offers/confirm/:token", to: redirect("/conversations")

  # No-login "Turn it back on", reached from the request-paused email.
  get "requests/resume/:token", to: "request_resumptions#show", as: :request_resumption
  post "requests/resume/:token", to: "request_resumptions#create"
end
