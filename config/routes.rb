Rails.application.routes.draw do
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'

  resources :sessions, only: [:create, :destroy]
  resource :home, only: [:show]

  root to: "home#show"

  get 'api/v2/user', to: 'api_proxy#get'
  get 'api/v2/subjects', to: 'api_proxy#get'
  get 'api/v2/assignments', to: 'api_proxy#get'
  get 'api/v2/study_materials', to: 'api_proxy#get'
  get 'api/v2/summary', to: 'api_proxy#get'
  get 'api/v2/review_statistics', to: 'api_proxy#get'

  get 'review_data/merged', to: 'review_data#merged'
  get 'srs/status', to: 'srs#status'
  get 'leeches', to: 'leeches#index', defaults: { format: 'json' }

  get 'ping', to: 'home#ping'
end