Rails.application.routes.draw do
  root to: 'homes#top'
  devise_for :users
  resources :books, only: [ :create, :show, :edit, :update, :destroy ] do
    resource :favorites, only: [:create, :destroy]
    resources :book_comments, only: [:create, :destroy]
  end
  resources :users, only: [:index, :show, :edit, :update]
  resources :quiz_collections do
    member do
      get :export
    end
    
    collection do
      get :export_user_based
    end
  end
  resources :quiz_collections, only: [:index, :show, :create, :destroy]
  
  
  get "/home/about" => "homes#about", as: "about"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
