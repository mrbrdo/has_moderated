class HookTest < ActiveRecord::Base
  has_moderated_create
  has_moderated :title
  
  moderation_creating do |m|
    # use title for checking the scope of self here
    m.attr_value = self.title + m.attr_value # just add 2 spaces
  end
end
