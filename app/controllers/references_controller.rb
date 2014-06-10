class ReferencesController < ApplicationController
  def show
    doi = params[:id]
    encoded_doi = URI.encode_www_form_component(doi)
    ris = Rails.cache.fetch("doi_#{encoded_doi}_ris") do
      url = "http://dx.doi.org/#{encoded_doi}"
      Plos::Api.http_get(url, "application/x-research-info-systems")
    end
    headers['Content-Disposition'] = "attachment; filename=#{encoded_doi}"
    render text: ris, content_type: "application/x-research-info-systems"
  end
end
