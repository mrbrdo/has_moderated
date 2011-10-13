module HasModerated
  module ModeratedAttributes
    module ClassMethods
      def has_moderated *args, &block
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we have to.
        send :include, InstanceMethods

        has_many :moderations, :as => :moderatable, :dependent => :destroy

        cattr_accessor :moderated_attributes
        cattr_accessor :moderated_options

        self.moderated_attributes ||= []
        self.moderated_options ||= {}

        args.each do |arg|
          if arg.respond_to?("[]")
            self.moderated_options = self.moderated_options.merge(arg)
          else
            self.moderated_attributes.push(arg.to_s)
          end
        end

        # use an attribute to temporarily disable moderation before_save filter
        attr_accessor :has_moderated_updating

        # send moderated attributes to moderation before saving the model
        before_save do
          if self.valid? && @has_moderated_updating != true &&
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
    
    module InstanceMethods
    
      def to_moderation
        moderations = []
        self.changes.each_pair do |att_name, values|
          att_name = att_name.to_s
          if self.class.moderated_attributes.include?(att_name) && !(values[0].blank? && values[1].blank?)
            moderations.push(create_moderation_with_hooks!({
              :moderatable_type => self.class.to_s,
              :moderatable_id => self.id,
              :attr_name => att_name,
              :attr_value => self.attributes[att_name].to_yaml
            }))
            self.send(att_name+"=", values[0])
          end
        end
      
        moderations
      end
    end
  end
end