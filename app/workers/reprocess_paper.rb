class ReprocessPaper
  include Sidekiq::Worker

  def perform(doi, days)
    paper = PaperResult.find_by(doi: doi)
    # check to make sure the paper still exists AND it hasn't been updated in the meantime
    return if paper.nil? || paper.updated_at > days.days.ago
    paper.destroy!
    AnalyzePaper.perform_async(doi)
  end
end
