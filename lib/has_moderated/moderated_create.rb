module HasModerated
  module ModeratedCreate
    module ClassMethods
      def has_moderated_create *options
        HasModerated::Common::init(self)
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        # save options for use later
        cattr_accessor :moderated_create_options
        self.moderated_create_options = (options.count > 0) ? options[0] : {}

        alias_method_chain :create_or_update, :moderation
      end
    end

    module ApplyModeration
      def self.apply(klass, value)
        rec = nil
        if value[:create].present?
          # create the main record
          rec = klass.new
          attrs = value[:create][:attributes]
          # bypass attr_accessible protection
          attrs && attrs.each_pair do |key, val|
            rec.send(key.to_s+"=", val) unless key.to_s == 'id'
          end
          Moderation.without_moderation { rec.save(:validate => false) }
          HasModerated::Associations::Base::ApplyModeration::apply(rec, value[:create])
        end
        rec
      end
    end

    module InstanceMethods
      def create_or_update_with_moderation *args
        if valid? && new_record? && !self.moderation_disabled
          to_moderation_created
          true
        else
          create_or_update_without_moderation *args
        end
      end

      def to_moderation_created
        options = self.class.moderated_create_options
        assoc_attrs = HasModerated::ActiveRecordHelpers::get_assocs_for_moderation(options[:with_associations], self)

        create_moderation_with_hooks!(:create => {
          :attributes => get_moderation_attributes,
          :associations => assoc_attrs
        })
      end
    end
  end
end
