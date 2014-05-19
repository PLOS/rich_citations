class RemoveOldSearches

  def self.run!
    new.run!
  end

  def run!
    remove_old_papers
    remove_old_results
  end

  private

  def remove_old_papers
    expiry_date = 4.days.ago
    PaperResult.where('updated_at < ?', expiry_date ).delete_all
  end

  def remove_old_results
    expiry_date = 3.days.ago
    ResultSet.where('updated_at < ?', expiry_date ).delete_all
  end

end