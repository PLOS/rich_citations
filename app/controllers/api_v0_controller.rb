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

class ApiV0Controller < ApplicationController
  protect_from_forgery with: :null_session
  
  before_action except: [:paper_list] do
    @doi = if params[:doi]
             params[:doi]
           else
             Id::Doi.extract(params[:id])
           end
    render status: 404, text: '' unless Id::Doi.is_plos_doi?(@doi)
  end

  def destroy
    paper = PaperResult.find_by(doi: @doi)
    json = paper.bibliographic
    ref_uris = json[:references].map { |r| "#{r[:uri_type]}:#{r[:uri]}" }
    PaperInfoCache.delete_all(identifier: ref_uris)
    paper.destroy!
    render status: :no_content, text: ''
  end

  def paper_list
    dois = PaperResult.all.select(:doi).map(&:doi)
    render json: dois
  end

  def papers
    # TODO : combine with code in papers controller
    paper = PaperResult.find_or_new_for_doi(@doi)
    if paper.should_start_analysis?
      paper.start_analysis!
      paper.save
    end
    response.content_type = Mime::JSON
    headers['Content-Disposition'] = %Q{attachment; filename="#{paper.doi}.json"} unless params[:inline]
    result = if paper.ready?
               json = paper.result.deep_dup.with_indifferent_access
               JsonUtilities.strip_uri_type!(json)
               json.to_json
             else
               ''
             end
    status = paper.ready? ? :ok : :accepted
    render(json: result, status: status)

    @paper = PaperResult.find_or_new_for_doi(@doi)
  end
end
