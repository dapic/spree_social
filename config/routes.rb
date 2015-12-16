Spree::Core::Engine.add_routes do
  devise_for :spree_user,
             class_name: Spree::User,
             only: [:omniauth_callbacks],
             controllers: {omniauth_callbacks: 'spree/omniauth_callbacks'},
             path: Spree::SocialConfig[:path_prefix]
  resources :user_authentications

  get 'account' => 'users#show', as: 'user_root'

  devise_scope :spree_user do
    get '/oauth_connect' => 'user_registrations#oauth_connect', :as => :oauth_connect
    post '/oauth_connect' => 'user_registrations#oauth_binding', :as => :oauth_binding
  end

  namespace :admin do
    resources :authentication_methods
  end
end
