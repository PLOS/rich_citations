class ReprocessPaper
  include Sidekiq::Worker

  def perform(doi)
    paper = PaperResult.find_by(doi: doi)
    return if paper.nil?
    paper.destroy!
    AnalyzePaper.perform_async(doi)
  end
end
