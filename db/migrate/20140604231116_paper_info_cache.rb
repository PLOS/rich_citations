class PaperInfoCache < ActiveRecord::Migration

  def change
    create_table :paper_info_caches do |table|
      table.string :identifier, unique:true, null:false
      table.text   :info_json
    end
  end

end
