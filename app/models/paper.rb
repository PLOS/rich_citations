class Paper < ActiveRecord::Base

  validates :doi, presence:true

  def self.find_by_doi(doi)
    self.where(doi:doi).first
  end

  def self.find_by_doi!(doi)
    self.where(doi:doi).first!
  end

  def self.calculate_for(doi)
    paper = find_by_doi(doi)
    if paper && paper.references_json.present?
      Rails.logger.info("Using cached #{doi}")
      paper.touch
      return paper
    end

    Rails.logger.info("Fetching #{doi} ...")
    xml = Plos::Api.document( doi )
    Rails.logger.info("Parsing #{doi} ...")
    parser = Plos::PaperParser.new(xml)
    references = parser.references

    paper = find_by_doi(doi) || new(doi:doi)
    paper.references_json = JSON.generate(references)
    paper.save!

    paper
  end

  def references
    @references ||= JSON.parse(references_json).with_indifferent_access
  end

end
