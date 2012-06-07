module HasModerated
  module ModeratedDestroy
    module ClassMethods
      def has_moderated_destroy *options
        HasModerated::Common::init(self)
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods
      
        alias_method_chain :destroy, :moderation
      end
    end
    
    module ApplyModeration
      def self.apply(moderation, value)
        if value[:destroy] == true
          moderation.moderatable.without_moderation { |m| m.destroy }
        end
      end
    end
    
    module InstanceMethods
      def destroy_with_moderation *args
        if @moderation_disabled == true
          destroy_without_moderation *args
        else
          to_moderation_destroyed
          true
        end
      end

      def to_moderation_destroyed
        create_moderation_with_hooks!(:destroy => true)
      end
    end
  end
end