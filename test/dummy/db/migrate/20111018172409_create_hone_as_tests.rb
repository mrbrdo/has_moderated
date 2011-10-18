class CreateHoneAsTests < ActiveRecord::Migration
  def change
    create_table :hone_as_tests do |t|
      t.integer :testable_id
      t.string :testable_type
      t.string :title

      t.timestamps
    end
  end
end
