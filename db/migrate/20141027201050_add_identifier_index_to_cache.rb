class AddIdentifierIndexToCache < ActiveRecord::Migration
  def change
    add_index :paper_info_caches, [:identifier]
  end
end
