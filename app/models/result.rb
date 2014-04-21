class Result < ActiveRecord::Base
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

  def self.find_or_new_for_analyze(params)
    list = Plos::DoiResolver.extract_doi_list(params[:query])
    return nil if list.empty?

    limit = list.count
    query = list[0..1].join(',')
    query += '…' if limit > 2
    query_result = list.map { |i| { id:i }  }

    find_params = {
        query:        query,
        limit:        limit,
        query_result: JSON.generate(query_result),
    }

    self.where(find_params).first || self.new(find_params)
  end

  def self.for_token(token)
    self.where(token:token).first!
  end

  def ready?
    analysis_json.present?
  end

  def has_matches?
    ready? && analysis_results[:match_count] && analysis_results[:match_count] > 0
  end

  def start_analysis!
    if ready?
      self.touch

    else
      # Note this does not prevent a task being started multiple times
      ThreadingHelpers.background("Analyze #{self.id}") do
        analyze!
      end

    end

  end

  def analysis_results
    @analysis_results ||= ready? ? JSON.parse(analysis_json).symbolize_keys_recursive! : nil
  end

  def matches
    analysis_results[:matches]
  end

  private

  def analyze!
    matching_dois = search_dois

    database = Plos::PaperDatabase.new

    matching_dois.each do |doi|
      paper = Paper.calculate_for(doi)
      database.add_paper(doi, paper.references)
    end
    Rails.logger.info("Completed Analysis")

    results = JSON.generate(database.results)
    update_attributes!(analysis_json:results)
  end

  def search_dois
    if self.query_result.blank?
      Rails.logger.info("Searching for #{self.query.inspect} (limit:#{self.limit}")
      matching = Plos::Api.search(self.query, query_type: "subject", rows: self.limit)
      self.update_attributes!(query_result: JSON.generate(matching))
      Rails.logger.info("Found #{matching.count} results")

    else
      matching = JSON.parse(self.query_result)
      Rails.logger.info("Using #{matching.count} cached query results")
    end

    matching.map { |r| r['id'] }
  end

  def set_token
    self.token = SecureRandom.urlsafe_base64(nil, false)
  end

  def normalize_fields
    unless self.query_result.present? # Analysis
      self.query &&= self.query.downcase
    end
  end

end
