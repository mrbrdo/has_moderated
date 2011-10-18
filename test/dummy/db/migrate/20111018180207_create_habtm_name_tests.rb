class CreateHabtmNameTests < ActiveRecord::Migration
  def change
    create_table :habtm_name_tests do |t|
      t.string :title

      t.timestamps
    end
    create_table :habtm_name_tests_tasks, :id => false do |t|
      t.integer :task_id
      t.integer :habtm_name_test_id
    end
  end
end
