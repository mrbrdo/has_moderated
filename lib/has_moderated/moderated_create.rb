module HasModerated
  module ModeratedCreate
    module ClassMethods
      def has_moderated_create *options
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        # use an attribute to temporarily disable moderation before_save filter
        attr_accessor :has_moderated_updating

        # save options for use later
        cattr_accessor :moderated_create_options
        self.moderated_create_options = (options.count > 0) ? options[0] : {} 

        alias_method_chain :create_or_update, :moderation
      end
    end
    
    module InstanceMethods
      def create_or_update_with_moderation *args
        if valid? && new_record? && @has_moderated_updating != true
          to_moderation_created
          true
        else
          create_or_update_without_moderation *args
        end
      end

      def to_moderation_created
        options = self.class.moderated_create_options
        assoc_attrs = HasModerated::Common::get_assocs_for_moderation(options[:with_associations], self)

        attr_value = {
          :main_model => get_moderation_attributes(self),
          :associations => assoc_attrs
        }

        create_moderation_with_hooks!({
          :moderatable_type => self.class.to_s,
          :moderatable_id => self.id,
          :attr_name => "-",
          :attr_value => attr_value.to_yaml
        })
      end
    end
  end
end