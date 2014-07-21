CitationTools::Application.routes.draw do

  root 'papers#index'

  get '', to:'results#index', as:'search'

  resources :results, only:[:index, :show] do
    member do
      get '/cited/:ref', action:'cited', constraints: {ref: /.+/}, format:false, as:'cited'
    end
    collection do
      post :search
      post :list
      post :parse
    end
  end

  resources :papers, only:[:show], format:false, id: /.+/
  resources :references, only:[:show], format:false, id: /.+/
  get '/view/:id/references/:referenceid', to: 'papers#reference', id:/.+/
  get '/view/:id', to: 'papers#view', id:/.+/ 
  get '/interstitial', to: 'papers#interstitial'
end
