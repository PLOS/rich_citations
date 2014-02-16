CitationTools::Application.routes.draw do

  resource :citation, only:   [:show] do
    member do
      get :search
    end
  end

  root 'citations#show'

end
