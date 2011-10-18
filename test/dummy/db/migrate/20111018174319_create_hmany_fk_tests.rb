class CreateHmanyFkTests < ActiveRecord::Migration
  def change
    create_table :hmany_fk_tests do |t|
      t.integer :something_id
      t.string :title

      t.timestamps
    end
  end
end
