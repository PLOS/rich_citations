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

class PapersController < ApplicationController

  def index
    if params[:doi].present? then
      doi = Id::Doi.extract( params[:doi] )
      if doi.blank?
        redirect_to root_url, flash: { error: "DOI is Invalid" }
      elsif !Id::Doi.is_plos_doi?(doi) && !Id::Doi.is_elife_doi?(doi) && !Id::Doi.is_peerj_doi?(doi)
        redirect_to root_url, flash: { error: "Not a PLOS or elife or PeerJ DOI" }
      else
        redirect_to action: 'view', id: Id::Doi.extract(doi)
      end
    end
  end

  def show
    @doi = Id::Doi.extract( params[:id] )

    raise "DOI is Invalid" if @doi.blank?
    raise "Not a PLOS DOI" unless Id::Doi.is_plos_doi?(@doi)

    @paper = PaperResult.find_or_new_for_doi(@doi)
    if @paper.should_start_analysis?
      @paper.start_analysis!
      @paper.save
    end
    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{@paper.doi}.js"} if !params[:inline]
        result = @paper.ready? ? @paper.result : { processing: true }
        status = @paper.ready? ? :ok : :created
        render json:result, status:status
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }

    end

  end

  def view
    @doi = params[:id]
    @journal_url = PaperResult.journal_url(@doi)
    @xml = Plos::Api.document(@doi)
    render layout: 'viewer'
  end

  def reference
    @doi = params[:id]
    @paper = PaperResult.calculate_for(params[:id])
    ref = @paper.bibliographic[:references].values.select{|r|r[:index] == params[:referenceid].to_i}.first
    render json: ref
  end

  def interstitial
    @doi = params[:from]
    @paper = PaperResult.calculate_for(params[:from])
    @ref = @paper.bibliographic[:references].values.select{|r|r[:index] == params[:to].to_i}.first
    render layout: 'plain'
  end
end
