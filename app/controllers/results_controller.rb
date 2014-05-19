class ResultsController < ApplicationController

  def index
    @search_result_set ||= ResultSet.new(
        query: 'Circadian Rhythms',
        limit: 50
    )
    @list_result_set ||= ResultSet.new

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
    @doi    = params[:doi]
    @cited  = @result_set.results[:citations][ @doi.to_sym ]
    raise ActiveRecord::RecordNotFound unless @cited

    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="cited #{@doi}.js"}
        render json: @cited
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }
    end

  end

  protected

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
