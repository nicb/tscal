#
# $Id: routes.rb 224 2010-02-26 17:43:15Z mtisi $
#
ActionController::Routing::Routes.draw do |map|
  map.resources :classrooms

  map.resources :places

  #
  # TODO: currently, only the methods set in :only arrays are implemented.
  #       For 0.2.1 the complete refactoring of these two controllers must be
  #       done
  #
  map.namespace(:at) do |ns|
   #
   # these resources require only the activated_topic id
   #
   ns.resources(:activated_topics,
                :member => { :mass_lesson_edit => :get, :mass_lesson_edit_manage => :put })
   #
   # these resources require only the lesson id
   #
   ns.resources :lessons, :member => { :remove => :delete }, :only => [:remove]
  end

  map.resources :topics

  map.resources :topic_titles

  map.resources :teachers

  map.resources :editions

  map.resources :courses

  map.resources :bo

	map.resources :lesson

	map.resources	:teachers

  map.resources :report, :only => [ :index ], :member => { :lessons => :get,
    :teacher => :get, :show_filtered_by_course => :get,
    :show_filtered_by_teaching_typology => :get,
    :show_filtered_by_delivery_type => :get,
    :show_filtered_by_activation => :get,
    :show_filtered_by_year => :get,
    :show_filtered_by_semester => :get,
    :show_filtered_by_teacher => :get,
    :show_filtered_by_teacher_typology => :get, }

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  #
  # this is a named route that displays a calendar with a given date (dd/mm/yyyy)
  #

  map.connect '/html', :controller => :calendar, :action => :show_html
  map.connect '/html/:day/:month/:year', :controller => :calendar, :action => :show_html

  #FIXME: this should be like the commented lines but we can't make it work
  #map.index '/js', :controller => :calendar, :action => :show_js
  map.index '/', :controller => :calendar, :action => :show_js

  map.connect 'calendar/get_lessons_json/', :controller => :calendar, :action => :get_lessons_json

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :index

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
