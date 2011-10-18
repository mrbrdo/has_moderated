class HmanyFkTest < ActiveRecord::Base
  belongs_to :bla, :class_name => "Task", :foreign_key => "something_id"
end
