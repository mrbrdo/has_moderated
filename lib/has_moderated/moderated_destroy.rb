module HasModerated
  module ModeratedDestroy
    module ClassMethods
      def has_moderated_destroy *options
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods
      
        # use an attribute to temporarily disable moderation before_save filter
        attr_accessor :has_moderated_updating
      
        alias_method_chain :destroy, :moderation
      end
    end
    
    module InstanceMethods
      def destroy_with_moderation *args
        if @has_moderated_updating == true
          destroy_without_moderation *args
        else
          to_moderation_destroyed
          true
        end
      end

      def to_moderation_destroyed
        create_moderation_with_hooks!({
          :moderatable_type => self.class.to_s,
          :moderatable_id => self.id,
          :attr_name => "-",
          :attr_value => "destroy"
        })
      end
    end
  end
end