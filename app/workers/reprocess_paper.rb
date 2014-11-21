class ReprocessPaper
  include Sidekiq::Worker

  def perform(doi)
    paper = Paper.find_by(doi: doi)
    paper.destroy!
    AnalyzePaper.perform_async(doi)
  end
end
