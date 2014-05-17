class RenamePaperResultColumns < ActiveRecord::Migration
  def change
    rename_column :paper_results, :references_json, :info_json
  end
end
