Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Custom health check that performs a database query and returns connection status.
  get "health" => "health#show", as: :health_check

  # Authentication routes
  post "auth/signup", to: "authentication#signup"
  post "auth/login", to: "authentication#login"
  post "auth/logout", to: "authentication#logout"

  # Group management routes
  resources :groups, only: [:index, :create, :update, :destroy] do
    member do
      post :add_user
    end
    # Nested product routes
    resources :products, only: [:index, :create]
  end

  # Shallow product routes
  resources :products, only: [:update, :destroy] do
    member do
      post :buy
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
