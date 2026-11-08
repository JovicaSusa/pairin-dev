Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  # Registrations without destroy: deleting an account is by request, as the privacy policy says.
  devise_for :users, skip: [:registrations], controllers: { sessions: "users/sessions" }
  devise_scope :user do
    get "users/cancel", to: "users/registrations#cancel", as: :cancel_user_registration
    get "users/sign_up", to: "users/registrations#new", as: :new_user_registration
    get "users/edit", to: "users/registrations#edit", as: :edit_user_registration
    patch "users", to: "users/registrations#update", as: :user_registration
    put "users", to: "users/registrations#update"
    post "users", to: "users/registrations#create"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show"

  # Defines the root path route ("/")
  root "home#index"

  get "privacy" => "pages#privacy", as: :privacy
  get "terms" => "pages#terms", as: :terms
  get "account-suspended" => "pages#account_suspended", as: :account_suspended

  # One-time step for accounts with no date of birth.
  resource :date_of_birth, only: [:show, :update]

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
    resources :pair_requests do
      patch :pause, on: :member
      patch :resume, on: :member
    end
  end

  resource :onboarding, only: [:show, :create] do
    post :skip
  end

  resources :partners, only: [:index, :show, :update], controller: "partnerships" do
    post :end_partnership, on: :member
    get :chat, on: :member
    resources :sessions, only: [:index, :create], controller: "partners/sessions" do
      member do
        patch :confirm
        patch :decline
        patch :withdraw
        patch :cancel
        get :calendar
      end
    end
    resources :resources, only: [:index, :create, :destroy], controller: "partners/resources"
  end

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

  # A partner search's shareable link, readable with no account.
  get "s/:token", to: "public_searches#show", as: :public_search
  get "s/:token/apply", to: "public_searches#apply", as: :public_search_apply

  # No-login Yes/No, reached from the weekly check-in email.
  get "check-ins/:token", to: "check_ins#show", as: :check_in
  post "check-ins/:token", to: "check_ins#create"

  # No-login Yes/No, reached from the "Did it happen?" email after a session.
  get "did-it-happen/:token", to: "session_answers#show", as: :session_answer
  post "did-it-happen/:token", to: "session_answers#create"

  # No-login "Pause this search", reached from the emails about a search.
  get "requests/pause/:token", to: "request_pauses#show", as: :request_pause
  post "requests/pause/:token", to: "request_pauses#create"

  # No-login unsubscribe from an optional email's footer and mail app.
  get "unsubscribe/:category/:token", to: "unsubscribes#show", as: :unsubscribe
  post "unsubscribe/:category/:token", to: "unsubscribes#create"

  # No-login "Turn it back on", reached from the request-paused email.
  get "requests/resume/:token", to: "request_resumptions#show", as: :request_resumption
  post "requests/resume/:token", to: "request_resumptions#create"
end
