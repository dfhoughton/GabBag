Rails.application.routes.draw do
  get 'favorites/index'

  get 'favorites/create'

  get 'favorites/destroy'

  get 'notifications/recent'

  get 'notifications/all'

  devise_for :users
  get 'welcome/index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'
  get 'anagrams/trial' => 'anagrams#trial'
  get 'anagrams/full' => 'anagrams#full'
  get 'anagrams/share/:recipient' => 'anagrams#share', as: :share
  get 'notifications/recent' => 'notifications#recent', as: :recent_notifications
  get 'notifications/unread' => 'notifications#unread', as: :unread_notifications
  post 'notifications/read' => 'notifications#read', as: :read_notifications
  get 'friends/prospects' => 'friends#prospects', as: :prospective_friends
  get 'friends/mine' => 'friends#mine', as: :my_friends
  delete 'favorites/delete' => 'favorites#destroy', as: :delete_favorite

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  resources :anagrams, :notifications, :favorites, :favorites, :friends

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
