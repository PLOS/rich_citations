CitationTools::Application.routes.draw do

  root 'results#index'

  get '', to:'results#index', as:'search'

  resources :results, only:[:index, :create, :show] do
    member do
      get '/cited/:doi', action:'cited', constraints: {doi: /.+/}, format:false, as:'cited'
    end
  end

  resources :papers, only:[:show], format:false, id: /.+/

end
