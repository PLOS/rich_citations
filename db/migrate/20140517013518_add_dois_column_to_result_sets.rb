class AddDoisColumnToResultSets < ActiveRecord::Migration
  def change
    rename_column :result_sets, :analysis_json, :results_json
    add_column    :result_sets, :dois, :text
  end
end
