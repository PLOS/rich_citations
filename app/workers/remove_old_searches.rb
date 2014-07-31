# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
