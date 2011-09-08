class AddTaskAllIdToSubtasks < ActiveRecord::Migration
  def change
    add_column :subtasks, :task_all_id, :integer
  end
end
