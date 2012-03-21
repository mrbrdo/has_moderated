require 'has_moderated/common'
require 'has_moderated/moderation_model'

require 'has_moderated/associations/base'
require 'has_moderated/associations/has_one'
require 'has_moderated/associations/collection'
require 'has_moderated/associations/has_many'

module HasModerated
  def self.included(base)
    HasModerated::Common::included(base)
    
    # TODO: only include class methods that can be called, lazy load everything else
    base.send :extend, HasModerated::Associations::Base::ClassMethods
  end
end

ActiveRecord::Base.send :include, HasModerated
