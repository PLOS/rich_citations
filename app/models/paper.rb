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
    if paper && paper.ready?
      Rails.logger.info("Using cached #{doi}")
      paper.touch
      return paper
    end

    Rails.logger.info("Fetching #{doi} ...")
    xml = Plos::Api.document( doi )
    Rails.logger.info("Parsing #{doi} ...")
    parser = Plos::PaperParser.new(xml)
    references = parser.paper_info

    paper = find_by_doi(doi) || new(doi:doi)
    paper.references_json = JSON.generate(references)
    paper.save!

    paper
  end

  def references
    @references ||= ready? ? JSON.parse(references_json).symbolize_keys_recursive! : nil
  end

  def ready?
    references_json.present?
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
