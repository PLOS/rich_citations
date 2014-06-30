class ReferencesController < ApplicationController
  def show
    format = params[:format] || "ris"
    content_type = case format
                   when "ris"
                     "application/x-research-info-systems"
                   when "bibtex", "bib"
                     "application/x-bibtex"
                   end
    encoded_doi = URI.encode_www_form_component(params[:id])
    data = Rails.cache.fetch("doi_#{encoded_doi}_#{format}") do
      url = "http://dx.doi.org/#{encoded_doi}"
      HttpUtilities.get(url, content_type)
    end
    render text: data, content_type: content_type
  end
end
