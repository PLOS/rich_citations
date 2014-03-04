class CreatePapers < ActiveRecord::Migration
  def change
    create_table :papers do |t|
      t.string :doi,              limit:255, null:false, unique:true
      t.text   :references_json,             null:false

      t.timestamps
    end
  end
end
