Rails.application.routes.draw do
  get "timeslots/index"
  get "timeslots/new"
  get "timeslots/edit"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root should point to UsersController#home (plural controller name)
  resources :users
  resources :reservations do
    member do
      patch :cancel
      get :cancel
    end
  end
  resources :tables
  resources :timeslots

  root "application#home"
  get    "/login",  to: "sessions#new"
  get    "/signup", to: "users#new",     as: :signup
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  get    "/admin",  to: "users#admin",   as: :admin_dashboard
  # Defines the root path route ("/")
  # root "posts#index"
end
