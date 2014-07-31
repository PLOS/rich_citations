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

class ResultsController < ApplicationController

  def index
    @search_result_set ||= ResultSet.new(
        query: 'Circadian Rhythms',
        limit: 50
    )
    @list_result_set ||= ResultSet.new
    @parsed_paper ||= PaperResult.new

    @available_result_sets = ResultSet.order(updated_at: :desc)

    render :index
  end

  def search
    @search_result_set = ResultSet.find_or_new_for_search( search_params )
    if @search_result_set.save
      @search_result_set.start_analysis!
      redirect_to result_path(@search_result_set.token)

    else
      index

    end
  end

  def list
    @list_result_set = ResultSet.find_or_new_for_list( list_params )
    if @list_result_set.nil?
      # Fake an object to keep form builders happy
      @list_result_set = ResultSet.new(list_params)
      @list_result_set.errors.add(:query, 'must be valid')
      index

    elsif @list_result_set.save
      @list_result_set.start_analysis!
      redirect_to result_path(@list_result_set.token)

    else
      index

    end
  end

  def parse
    @doi = Id::Doi.extract( parse_params[:doi] )

    if @doi.blank?
      # Fake an object to keep form builders happy
      @parsed_paper = PaperResult.new(parse_params)
      @parsed_paper.errors.add(:doi, 'must be valid')
      index

    elsif ! Id::Doi.is_plos_doi?(@doi)
      # Fake an object to keep form builders happy
      @parsed_paper = PaperResult.new(parse_params)
      @parsed_paper.errors.add(:doi, 'must be a PLOS doi')
      index

    else
      @parsed_paper = PaperResult.find_or_new_for_doi(@doi)
      @parsed_paper.start_analysis!

      if @parsed_paper.save
        redirect_to paper_path(@parsed_paper.doi)
      else
        index
      end

    end
  end

  def show
    @result_set = ResultSet.for_token( params.require(:id) )

    respond_to do |format|

      format.html {
        if @result_set.ready?
          @sort_col  = params[:sort].to_sym
          @sort_desc = params[:dir] == 'desc'
          @citations = @result_set.results[:citations] || {}
          @citations = sort_citations(@citations, @sort_col, @sort_desc)
        end
      }

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{@result_set.query}.js"}
        render json: @result_set.results
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }
    end

  end

  def cited
    @result_set = ResultSet.for_token( params.require(:id) )
    @ref    = URI.decode_www_form_component( params[:ref] )
    @cited  = @result_set.results[:citations][ @ref.to_sym ]
    raise ActiveRecord::RecordNotFound unless @cited

    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{filename(@ref)}"}
        render json: @cited
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }
    end

  end

  protected

  def filename(name)
    'cited ' + name.tr(':','-') + '.js'
  end

  def sort_link(text, column)
    options = {sort:column}
    if column == @sort_col
      options[:dir] = @sort_desc ? nil : 'desc'
    end

    view_context.link_to(text, result_path(@result_set.token, options))
  end
  helper_method :sort_link

  private

  def search_params
    params.require(:result_set).permit(:query, :limit)
  end

  def list_params
    params.require(:result_set).permit(:query)
  end

  def parse_params
    params.require(:paper_result).permit(:doi)
  end

  def sort_citations(citations, column, descending)

    if column
      results = citations.sort_by { |_,v| v[column] }
      descending ? results.reverse.to_h : results.to_h
    elsif descending
      citations.to_a.reverse.to_h
    else
      # Parser ensures that citations are sorted
      citations
    end

  end

end
