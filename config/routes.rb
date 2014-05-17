CitationTools::Application.routes.draw do

  root 'results#index'

  get '', to:'results#index', as:'search'

  resources :results, only:[:index, :show] do
    member do
      get '/cited/:doi', action:'cited', constraints: {doi: /.+/}, format:false, as:'cited'
    end
    collection do
      post :search
      post :list
    end
  end

  resources :papers, only:[:show], format:false, id: /.+/

end
