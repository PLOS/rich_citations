class PaperInfoCache < ActiveRecord::Migration

  def change
    create_table :paper_info_caches do |t|
      t.string :identifier, unique:true, null:false
      t.text   :info_json

      t.timestamps
    end
  end

end
