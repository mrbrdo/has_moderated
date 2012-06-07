require 'has_moderated/common'
require 'has_moderated/user_hooks'
require 'has_moderated/moderation_model'

require 'has_moderated/active_record/active_record_helpers'
require 'has_moderated/associations/base'
require 'has_moderated/associations/has_one'
require 'has_moderated/associations/collection'


require 'has_moderated/moderated_attributes'
require 'has_moderated/moderated_create'
require 'has_moderated/moderated_destroy'

require 'has_moderated/carrier_wave'

module HasModerated
  def self.included(base)
    HasModerated::Common::included(base)
    base.send :extend, HasModerated::UserHooks::ClassMethods
    
    # TODO: only include class methods that can be called, lazy load everything else
    base.send :extend, HasModerated::Associations::Base::ClassMethods
    base.send :extend, HasModerated::ModeratedAttributes::ClassMethods
    base.send :extend, HasModerated::ModeratedCreate::ClassMethods
    base.send :extend, HasModerated::ModeratedDestroy::ClassMethods
  end
end

ActiveRecord::Base.send :include, HasModerated
