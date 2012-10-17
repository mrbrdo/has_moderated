module HasModerated
  module ModeratedAttributes
    module ClassMethods
      def has_moderated *args, &block
        HasModerated::Common::init(self)
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        cattr_accessor :moderated_attributes
        cattr_accessor :moderated_options

        self.moderated_attributes ||= []
        self.moderated_options ||= {}

        args.each do |arg|
          if arg.class == Hash || arg.class == HashWithIndifferentAccess
            self.moderated_options = self.moderated_options.merge(arg)
          else
            self.moderated_attributes.push(arg.to_s)
          end
        end

        # send moderated attributes to moderation before saving the model
        before_save do
          if self.valid? && !self.moderation_disabled &&
            # don't save moderated attributes if create is moderated and it's a new record
            !(self.class.respond_to?("moderated_create_options") && new_record?)
            moderations = self.to_moderation
            if self.id.blank?
              @pending_moderations ||= []
              @pending_moderations.concat(moderations)
            end
          end
        end

        # when creating a new record, we must update moderations' id after it is known (after create)
        # TODO is this even necessary when using assoc.create ?
        after_create do
          if !self.id.blank? && !@pending_moderations.blank?
            @pending_moderations.each do |m|
              m.update_attributes(:moderatable_id => self.id)
            end
            @pending_moderations.clear
          end
        end
      end
    end

    module ApplyModeration
      def self.apply(rec, value)
        if value[:attributes].present?
          rec.without_moderation do
            value[:attributes].each_pair do |attr_name, attr_value|
              # bypass attr_accessible protection
              rec.send(attr_name.to_s+"=", attr_value)
            end
          end
        end
        rec
      end
    end

    module InstanceMethods
      def to_moderation
        moderations = []
        self.changes.each_pair do |att_name, values|
          att_name = att_name.to_s
          if self.class.moderated_attributes.include?(att_name) && !(values[0].blank? && values[1].blank?)
            moderations.push(create_moderation_with_hooks!(
              :attributes => {
                att_name => self.get_moderation_attributes[att_name]
              }
            ))
            self.send(att_name+"=", values[0])
          end
        end

        moderations
      end
    end
  end
end
