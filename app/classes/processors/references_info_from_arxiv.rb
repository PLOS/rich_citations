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

require 'uri'

module Processors
  class ReferencesInfoFromArxiv < Base
    include Helpers

    def process
      references = references_without_info(:arxiv)
      fill_info_for_references( references ) if references.present?
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    # cf http://arxiv.org/help/api/user-manual#title_id_published_updated

    API_URL = 'http://export.arxiv.org/api/query?max_results=1000'

    def fill_info_for_references(references)
      reference_ids = references.map { |ref| ref[:id]}

      results = fetch_results_for_ids(reference_ids)
      results.remove_namespaces!

      results.css('feed entry').each do |result|
        info = convert_result_to_info(result)
        next unless info.present?

        ref = reference_by_identifier(:arxiv, info[:ARXIV_VER]) ||
              reference_by_identifier(:arxiv, info[:ARXIV])

        next unless ref
        ref[:info] ||= {}
        ref[:info].merge!(info)
      end

    end

    def fetch_results_for_ids(ids)
      data  = 'id_list=' + ids.join(',')
      xml   = HttpUtilities.post(API_URL, data,
                                 'Content-Type' => Mime::URL_ENCODED_FORM, 'Accept' => Mime::ATOM  )
      Nokogiri::XML(xml)
    end

    def convert_result_to_info(result)
      @result = result
      id      = Id::Arxiv.extract( value('> id') )

      {
          info_source:         'arXiv',
          ARXIV:               Id::Arxiv.without_version( id ),
          ARXIV_VER:           id,
          DOI:                 Id::Doi.extract( value('> doi') || link_value('doi') ),
          title:               xml('> title'),
          # subtitle:
          issued:              date_value('> published'),
          subject:             subjects,
          author:              authors,
          # page:
          :'container-title'=> value('> journal_ref'),
          abstract:            xml('> summary'),
          URL:                 link_value('pdf'),
      }.compact

    end

    def value(selector)
      node = @result.at_css(selector)
      node && node.text.presence
    end

    def xml(selector)
      node = @result.at_css(selector)
      node && node.inner_html.strip.presence
    end

    def date_value(selector)
      node = @result.at_css(selector)
      return nil unless node.present? && node.text.present?
      date = DateTime.parse(node.text)
      [[ date.year, date.month, date.day ]]
    end

    def link_value(title)
      node = @result.at_css("> link[title=#{title}]")
      node && node['href'].presence
    end

    def subjects
      nodes = @result.css('> category')
      nodes.map { |node| subject_for(node) }.compact.presence
    end

    def subject_for(node)
      node['term'].presence
    end

    def authors
      nodes = @result.css('> author')
      nodes.map { |node| author_for(node) }.compact.presence
    end

    def author_for(node)
      {
          literal:     node.at_css('name').try(:text),
          affiliation: node.at_css('affiliation').try(:text),
      }.compact.presence
    end

  end

end
