class Subtask < ActiveRecord::Base
  belongs_to :task
  belongs_to :task_all
end
