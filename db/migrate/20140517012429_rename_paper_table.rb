class RenamePaperTable < ActiveRecord::Migration
  def change
    rename_table :papers, :paper_results
  end
end
