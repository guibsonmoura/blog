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

  # Like a comment (anonymous-friendly toggle).
  post "comments/:comment_id/like", to: "comment_likes#create", as: :comment_like

  # Public reader OAuth (Google + Microsoft). The request-phase POST to
  # /auth/:provider is handled by the OmniAuth middleware itself.
  match  "auth/:provider/callback", to: "readers/sessions#create",  via: [ :get, :post ], as: :reader_auth_callback
  match  "auth/failure",            to: "readers/sessions#failure", via: [ :get, :post ]
  delete "reader/logout",           to: "readers/sessions#destroy", as: :reader_logout

  get    "superadmin/login",  to: "admin/sessions#new",     as: :superadmin_login
  post   "superadmin/login",  to: "admin/sessions#create"
  delete "superadmin/logout", to: "admin/sessions#destroy", as: :superadmin_logout

  namespace :admin do
    root "posts#index"

    post "markdown_preview", to: "markdown_previews#create"

    resources :images, only: [ :create ]
    resources :posts do
      member { post :retranslate }
    end
    resources :comments, only: [ :destroy ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
