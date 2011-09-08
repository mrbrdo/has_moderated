class TaskAll < ActiveRecord::Base
  has_moderated_create :with_associations => :all
  has_many :subtasks
end
