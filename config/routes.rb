Movieselector::Application.routes.draw do

  resources :lists do
    get 'page/:page', :action => :index, :on => :collection
  end

  root :to => "home#index"
  get "/autocomplete", :to => "home#autocomplete", :as => :autocomplete_home
  
  get "/companies/autocomplete", :to => "companies#autocomplete", :as => :autocomplete_companies
  resources :companies do
    get 'page/:page', :action => :index, :on => :collection
  end

  get "/movies/autocomplete", :to => "movies#autocomplete", :as => :autocomplete_movies
  resources :movies do    
    get 'page/:page', :action => :index, :on => :collection
    member do
      post 'add_movie_to_collection', :as => :add_movie_to_collection
      post 'add_movie_to_watched', :as => :add_movie_to_watched
      post 'add_movie_to_watchlist', :as => :add_movie_to_watchlist
    end
  end

  get "/actors/autocomplete", :to => "actors#autocomplete", :as => :autocomplete_actors
  resources :actors do
    get 'page/:page', :action => :index, :on => :collection
  end

  get "/writers/autocomplete", :to => "writers#autocomplete", :as => :autocomplete_writers
  resources :writers do
    get 'page/:page', :action => :index, :on => :collection
  end

  get "/directors/autocomplete", :to => "directors#autocomplete", :as => :autocomplete_directors
  resources :directors do
    get 'page/:page', :action => :index, :on => :collection
  end

  get "/languages/autocomplete", :to => "languages#autocomplete", :as => :autocomplete_languages
  resources :languages do
    get 'page/:page', :action => :index, :on => :collection
  end

  get "/countries/autocomplete", :to => "countries#autocomplete", :as => :autocomplete_countries
  resources :countries do
    get 'page/:page', :action => :index, :on => :collection
  end

  get "/keywords/autocomplete", :to => "keywords#autocomplete", :as => :autocomplete_keywords
  resources :keywords do
    get 'page/:page', :action => :index, :on => :collection
  end

  get "/genres/autocomplete", :to => "genres#autocomplete", :as => :autocomplete_genres
  resources :genres do
    get 'page/:page', :action => :index, :on => :collection
  end
  
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  resources :users, :only => [:index, :show, :edit, :update ] do
    get 'library', :as => :library 
    get 'watchlist', :as => :watchlist
    resources :movies do
      get 'page/:page', :action => :index, :on => :collection
    end        
    resources :settings, :only => [:index, :show, :edit, :update ] do
      member do
        get 'import_trakt', :as => :import_trakt
        get 'import_facebook', :as => :import_facebook
        get 'check_trakt_import_state', :as => :check_trakt_import_state
      end
    end
  end
  get "/:user_id", :to => "users#show", :as => :friendly_user
  get "/:user_id/movies", :to => "movies#index", :as => :friendly_user_movie
  get "/:user_id/settings", :to => "settings#index", :as => :friendly_user_settings
  get "/:user_id/library", :to => "users#library", :as => :friendly_user_movie_library
  get "/:user_id/watchlist", :to => "users#watchlist", :as => :friendly_user_movie_watchlist
  
  mount Searchjoy::Engine, at: "admin/searchjoy"
end
