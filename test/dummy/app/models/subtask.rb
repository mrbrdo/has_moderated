class Subtask < ActiveRecord::Base
  attr_accessible :title, :desc
  belongs_to :task
end
