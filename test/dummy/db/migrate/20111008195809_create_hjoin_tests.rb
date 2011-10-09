class CreateHjoinTests < ActiveRecord::Migration
  def change
    create_table :hjoin_tests do |t|
      t.string :title

      t.timestamps
    end
    create_table :hjoin_tests_tasks do |t|
      t.integer :task_id
      t.integer :hjoin_test_id
    end
  end
end
