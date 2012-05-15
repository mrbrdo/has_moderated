class TaskConnection < ActiveRecord::Base
  belongs_to :renamed_task, :class_name => "Task", :foreign_key => "m1_id"
  belongs_to :renamed_subtask, :class_name => "Subtask", :foreign_key => "m2_id"
end
