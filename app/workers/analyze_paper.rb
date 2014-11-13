class AnalyzePaper
  include Sidekiq::Worker

  def perform(doi)
    paper = PaperResult.find_or_new_for_doi(doi)
    return if paper.ready?
    paper.analyze!
    paper.touch
    paper.save
  end
end
