Rails.application.routes.draw do
  root "posts#index"

  get "set_locale/:locale", to: "locales#update", as: :set_locale
  get "about",              to: "pages#about",   as: :about
  get "feed.xml",           to: "feed#index",    as: :feed, defaults: { format: :xml }
  get "search",             to: "search#index",  as: :search

  resources :posts, only: [ :index, :show ] do
    resources :comments, only: [ :create ]
    resources :reactions, only: [ :create ]
  end

  get    "superadmin/login",  to: "admin/sessions#new",     as: :superadmin_login
  post   "superadmin/login",  to: "admin/sessions#create"
  delete "superadmin/logout", to: "admin/sessions#destroy", as: :superadmin_logout

  namespace :admin do
    root "posts#index"

    post "markdown_preview", to: "markdown_previews#create"

    resources :images, only: [ :create ]
    resources :posts
    resources :comments, only: [ :destroy ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
