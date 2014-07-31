# coding: utf-8
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

class ResultSet < ActiveRecord::Base
  before_create :set_token
  before_save   :normalize_fields

  validates :query, presence:true
  validates :limit, presence:true, numericality: { only_integer:true, greater_than:0, less_than_or_equal_to:500 }

  def self.find_or_new_for_search(params)
    params[:query] = params[:query].try(:strip)

    find_params = params.dup
    find_params[:query] = find_params[:query].try(:downcase)

    self.where(find_params).first || self.new(params)
  end

  def self.find_or_new_for_list(list)
    list = Id::Doi.extract_list(list[:query])
    return nil if list.empty?

    limit = list.count
    query = list[0..1].join(',').downcase
    query += '…' if limit > 2

    find_params = {
        query: query,
        limit: limit,
        dois:  JSON.generate(list),
    }

    self.where(find_params).first || self.new(find_params)
  end

  def self.for_token(token)
    self.where(token:token).first!
  end

  def ready?
    results_json.present?
  end

  def has_matches?
    ready? && results[:match_count] && results[:match_count] > 0
  end

  def start_analysis!
    if ready?
      self.touch

    else
      # Note this does not prevent a task being started multiple times
      ThreadingHelpers.background("Analyze ResultSet:#{self.id}") do
        analyze!
      end

    end

  end

  def results
    @results ||= ready? ? JSON.parse(results_json).symbolize_keys_recursive! : nil
  end

  def matches
    results[:matches]
  end

  private

  def analyze!
    matching_dois = search_dois

    database = PaperDatabase.new

    matching_dois.each do |doi|
      paper = PaperResult.calculate_for(doi)
      database.add_paper(doi, paper.info)
    end
    Rails.logger.info("Completed Analysis")

    results = JSON.generate(database.results)
    update_attributes!(results_json:results)
  end

  def search_dois
    if self.dois.blank?
      Rails.logger.info("Searching for #{self.query.inspect} (limit:#{self.limit}")
      matching = Plos::Api.search(self.query, query_type: "subject", rows: self.limit)
      self.update_attributes!(query_result: JSON.generate(matching))
      Rails.logger.info("Found #{matching.count} results")

      doi_list = matching.map { |r| r['id'] }
      update_attributes!( dois: JSON.generate(doi_list) )

    else
      doi_list = JSON.parse(self.dois)
      Rails.logger.info("Using #{doi_list.count} cached query results")
    end

    doi_list
  end

  def set_token
    self.token = SecureRandom.urlsafe_base64(nil, false)
  end

  def normalize_fields
    unless self.dois.present? # Analysis
      self.query &&= self.query.downcase
    end
  end

end
