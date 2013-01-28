KaryotypeResource::Application.routes.draw do
  get "cancer/index"

  get "cancer/show"

  get "data_source/index"

  get "data_source/show"

  get "cell_line/show"

  get "cell_line/index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

  root :to => 'karyotype#index'
  match "/karyotype" => 'karyotype#index'

  namespace :karyotype do
    resources :breakpoint, :only => [:index, :show]
    resources :cell_line, :only => [:index, :show]
    resources :data_source, :only => [:index, :show]
    resources :cancer, :only =>[:index, :show]
  end

  resources :karyotype, :only => [:index, :show]

  #resources :karyotype do
  #  get 'breakpoints', :on => :collection
  #end


  # Sample of regular route:

  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end


  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  #match ':controller(/:action(/:id))(.:format)'
  #map.root    :controller => ""
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'

end
