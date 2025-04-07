Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Onboarding routes
  get 'onboarding/welcome', to: 'onboarding#welcome', as: :onboarding_welcome
  get 'onboarding/credits', to: 'onboarding#credits', as: :onboarding_credits
  get 'onboarding/solo_mode', to: 'onboarding#solo_mode', as: :onboarding_solo_mode
  get 'onboarding/paired_mode', to: 'onboarding#paired_mode', as: :onboarding_paired_mode
  get 'onboarding/validation', to: 'onboarding#validation', as: :onboarding_validation
  get 'onboarding/complete', to: 'onboarding#complete', as: :onboarding_complete
  
  # Add a dashboard route
  get 'dashboard', to: 'dashboard#index', as: :dashboard
  
  # Define root path
  root "dashboard#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
