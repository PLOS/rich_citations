class ReferencesController < ApplicationController
  def show
    format = params[:format] || "ris"
    content_type = case format
                   when "ris"
                     "application/x-research-info-systems"
                   when "bibtex"
                     "application/x-bibtex"
                   end
    encoded_doi = URI.encode_www_form_component(params[:id])
    ris = Rails.cache.fetch("doi_#{encoded_doi}_#{format}") do
      url = "http://dx.doi.org/#{encoded_doi}"
      Plos::Api.http_get(url, content_type)
    end
    headers['Content-Disposition'] = "attachment; filename=#{encoded_doi}"
    render text: ris, content_type: content_type
  end
end
