class HookTest < ActiveRecord::Base
  has_moderated_create
  has_moderated :title
  
  moderation_creating do |m|
    m.attr_value = "  " + m.attr_value # just add 2 spaces
  end
end
