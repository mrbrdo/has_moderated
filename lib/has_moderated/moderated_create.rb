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
        self.moderated_create_options = (options.count > 0) ? options[0] : nil 

        alias_method_chain :create_or_update, :moderated_check
      end
    end
  end
end