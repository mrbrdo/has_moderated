class Task < ActiveRecord::Base
  attr_accessible :title
  has_many :subtasks
  has_many :task_photos
  has_moderated :title, :desc, { :with_associations => [:subtasks] }
  has_moderated_create :with_associations => [:subtasks, :task_photos]
  has_moderated_destroy
end
