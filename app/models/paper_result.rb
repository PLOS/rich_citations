class PaperResult < ActiveRecord::Base

  validates :doi, presence:true

  def self.find_by_doi(doi)
    self.where(doi:doi).first
  end

  def self.find_by_doi!(doi)
    self.where(doi:doi).first!
  end

  def self.find_or_new_for_doi(doi)
    params = { doi:doi }
    self.where(params).first || self.new(params)
  end

  def self.calculate_for(doi)
    result = find_by_doi(doi)
    if result && result.ready?
      Rails.logger.info("Using cached #{doi}")
      result.touch
      return result
    end

    Rails.logger.info("Fetching #{doi} ...")
    xml = Plos::Api.document( doi )
    Rails.logger.info("Parsing #{doi} ...")
    info = PaperParser.parse_xml(xml)

    result = find_by_doi(doi) || new(doi:doi)
    result.info_json = JSON.generate(info)
    result.save!

    result
  end

  def info
    @info ||= ready? ? JSON.parse(info_json).symbolize_keys_recursive! : nil
  end
  alias result info

  def should_start_analysis?
    !ready? && ( new_record? || timed_out?)
  end

  def start_analysis!
    if ready?
      self.touch

    else
      # Note this does not prevent a task being started multiple times
      ThreadingHelpers.background("Analyze PaperResult:#{self.id}") do
        analyze!
      end

    end

  end

  def ready?
    info_json.present?
  end

  def self.journal_url(doi)
    case doi
    when /journal\.pone/
      "http://www.plosone.org"
    when /journal\.pbio/
      "http://www.plosbiology.org"
    when /journal\.pmed/
      "http://www.plosmedicine.org"
    when /journal\.pgen/
      "http://www.plosgenetics.org"
    when /journal\.pbci/
      "http://www.ploscompbio.org"
    when /journal\.ppat/
      "http://www.plospathogens.org"
    when /journal\.pntd/
      "http://www.plosntds.org"
    else
      raise Exception.new("Unknown journal found in #{doi}")
    end
  end

  private

  def analyze!
    if ready?
      Rails.logger.info("Using cached #{doi}")
      touch
    end

    Rails.logger.info("Fetching #{doi} ...")
    xml = Plos::Api.document( doi )
    Rails.logger.info("Parsing #{doi} ...")
    info = PaperParser.parse_xml(xml)

    self.info_json = JSON.generate(info)
    self.save!
  end

  def timed_out?
    Time.now - updated_at > 2.minutes
  end
end
