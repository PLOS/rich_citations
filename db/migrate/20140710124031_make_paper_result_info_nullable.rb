class MakePaperResultInfoNullable < ActiveRecord::Migration

  def change
    change_column_null :paper_results, :info_json, true
  end

end
