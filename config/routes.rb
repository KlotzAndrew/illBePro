Rails.application.routes.draw do
  resources :prizes

  resources :scores
  get 'leaderboard', to: 'scores#leaderboard'

  resources :geodelivers

  resources :ignindices
  get 'summoner', to: 'ignindices#index', as: :summoner
  get 'get_started', to: 'ignindices#get_started', as: :get_started
  get 'games', to: 'ignindices#games', as: :games
  get 'setup', to: "ignindices#get_setup", as: :setup
  get 'reset_setup', to: "ignindices#reset_setup", as: :reset_setup
  get 'zone', to: "ignindices#zone"
  
  resources :profiles

  devise_for :users
  
  devise_scope :user do
    get 'register', to: 'devise/registrations#new', as: :register
    get 'login', to: 'devise/sessions#new', as: :login
    get 'logout', to: 'devise/sessions#destroy', as: :logout
  end


  resources :statuses
  get 'challenges', to: 'statuses#index', as: :challenges
  

# authenticated :user do
#   root to: 'staticpages#homepage', as: :authenticated_root
# end

# unauthenticated do
  root to: "ignindices#landing_page"
# end



#static_page routes. so many.
  get 'teaser_summoner', to: "staticpages#teaser_summoner"
  get 'teaser_challenges', to: "staticpages#teaser_challenges"
  get 'teaser_prize_zone', to: "staticpages#teaser_prize_zone"
  get 'current_achievement', to: "staticpages#current_achievement"
  get 'dash', to: "staticpages#dash"
  
  get 'about', to: "staticpages#about"
  get 'contact', to: "staticpages#contact"
  get 'faq', to: "staticpages#faq"
  # get 'home', to: "staticpages#home"
  get 'privacy', to: "staticpages#privacy"
  get 'terms_of_service', to: "staticpages#terms_of_service"



  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
