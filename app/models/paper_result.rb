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

end
