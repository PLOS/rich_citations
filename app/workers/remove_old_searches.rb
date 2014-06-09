class RemoveOldSearches

  def self.run!
    new.run!(false)
  end

  def self.run_all!
    new.run!(true)
  end

  def run!(all)
    @all = all
    remove_old_papers
    remove_old_results
    remove_old_info_caches
  end

  private

  def remove_old_papers
    expiry_date = @all ? Time.now : 4.days.ago
    PaperResult.where('updated_at < ?', expiry_date ).delete_all
  end

  def remove_old_results
    expiry_date = @all ? Time.now : 3.days.ago
    ResultSet.where('updated_at < ?', expiry_date ).delete_all
  end

  def remove_old_info_caches
    expiry_date  = @all ? Time.now : 10.days.ago
    PaperInfoCache.where('updated_at < ?', expiry_date ).delete_all
  end

end