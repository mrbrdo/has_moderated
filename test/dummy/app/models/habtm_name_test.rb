class HabtmNameTest < ActiveRecord::Base
  has_and_belongs_to_many :owners, :class_name => "Task"
end
