class CreateResults < ActiveRecord::Migration

  def change
    create_table :results do |t|
      t.string  :token,   null:false,  limit:64
      t.string  :query,   null:false
      t.integer :limit,   null:false
      t.text    :query_result
      t.text    :analysis_json

      t.timestamps
    end
  end

end
