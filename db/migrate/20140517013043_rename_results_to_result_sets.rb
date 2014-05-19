class RenameResultsToResultSets < ActiveRecord::Migration
  def change
    rename_table :results, :result_sets
  end
end
