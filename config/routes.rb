# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
  get '/v0/paper', to: 'api_v0#paper'
end
