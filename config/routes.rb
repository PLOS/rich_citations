CitationTools::Application.routes.draw do

  root 'results#index'

  get '', to:'results#index', as:'search'

  resources :results, only:[:index, :create, :show]

  resources :papers, only:[:show], format:false, id: /.+/

end
