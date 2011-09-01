class Task < ActiveRecord::Base
  attr_accessible :title
  has_many :subtasks
  has_moderated :title, :desc
  has_moderated_existance :with_associations => [:subtasks]
end
