require 'has_moderated/associations/base'
require 'has_moderated/associations/collection'
require 'has_moderated/associations/has_many'

module HasModerated
  def self.included(base)
    base.send :extend, HasModerated::Associations::Base::ClassMethods
    base.send :include, HasModerated::Associations::Collection::InstanceMethods
    base.send :extend, HasModerated::Associations::HasMany::ClassMethods
  end
end

ActiveRecord::Base.send :include, HasModerated
