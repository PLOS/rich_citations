class PaperResult < ActiveRecord::Base

  validates :doi, presence:true

  def self.find_by_doi(doi)
    self.where(doi:doi).first
  end

  def self.find_by_doi!(doi)
    self.where(doi:doi).first!
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

  def ready?
    info_json.present?
  end

  def journal_url
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
end
