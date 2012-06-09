module HasModerated
  class Railtie < Rails::Railtie
    initializer "has_moderated.include_in_activerecord" do
      ActiveSupport.on_load :active_record do
        include HasModerated::Common::InstanceMethods
        extend HasModerated::UserHooks::ClassMethods
        extend HasModerated::Associations::Base::ClassMethods
        extend HasModerated::ModeratedAttributes::ClassMethods
        extend HasModerated::ModeratedCreate::ClassMethods
        extend HasModerated::ModeratedDestroy::ClassMethods
      end
    end
  end
end