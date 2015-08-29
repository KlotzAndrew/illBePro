Rails.application.routes.draw do

  resources :achievements, only: [:index, :create]

  resources :ignindices, only: [:index, :show, :create, :update]
  get 'summoner',             to: 'ignindices#index', as: :summoner
  get 'games',                to: 'ignindices#games', as: :games
  get 'setup',                to: "ignindices#get_setup", as: :setup
  get 'zone',                 to: "ignindices#zone"
  
  resources :statuses
  get 'challenges',           to: 'statuses#index', as: :challenges
  
  authenticated :user do
    root                      to: 'statuses#new', as: :authenticated_root
  end
  unauthenticated do
    root                      to: "ignindices#landing_page"
  end

  devise_for :users
  devise_scope :user do
    get 'register',           to: 'devise/registrations#new', as: :register
    get 'login',              to: 'devise/sessions#new', as: :login
    get 'logout',             to: 'devise/sessions#destroy', as: :logout
  end

  get 'scores',               to: 'scores#index'
  get 'leaderboard',          to: 'scores#leaderboard'

  get 'current_achievement',  to: "staticpages#current_achievement"
  get 'papa_johns',           to: "staticpages#papa_johns"
  get 'dash',                 to: "staticpages#dash"
  get 'about',                to: "staticpages#about"
  get 'contact',              to: "staticpages#contact"
  get 'faq',                  to: "staticpages#faq"
  get 'privacy',              to: "staticpages#privacy"
  get 'terms_of_service',     to: "staticpages#terms_of_service"
end
