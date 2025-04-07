Rails.application.routes.draw do
  # Devise routes with custom controller
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Onboarding routes
  get 'onboarding/welcome'
  get 'onboarding/credits'
  get 'onboarding/solo_mode'
  get 'onboarding/paired_mode'
  get 'onboarding/validation'
  get 'onboarding/complete'
  
  # Dashboard
  get 'dashboard', to: 'dashboard#index'
  
  # Set root path
  root 'dashboard#index'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
