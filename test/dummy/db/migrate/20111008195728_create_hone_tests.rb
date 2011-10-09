class CreateHoneTests < ActiveRecord::Migration
  def change
    create_table :hone_tests do |t|
      t.integer :task_id

      t.timestamps
    end
  end
end
