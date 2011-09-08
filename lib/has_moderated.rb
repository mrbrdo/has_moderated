module HasModerated

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def has_moderated *args, &block
      # Lazily include the instance methods so we don't clutter up
      # any more ActiveRecord models than we have to.
      send :include, InstanceMethods

      has_many :moderations, :as => :moderatable, :dependent => :destroy
      
      cattr_accessor :moderated_attributes

      self.moderated_attributes ||= []

      args.each do |arg|
        self.moderated_attributes.push(arg.to_s)
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
    
    def has_moderated_destroy *options
      # Lazily include the instance methods so we don't clutter up
      # any more ActiveRecord models than we have to.
      send :include, InstanceMethods
      
      # use an attribute to temporarily disable moderation before_save filter
      attr_accessor :has_moderated_updating
      
      alias_method_chain :destroy, :moderated_check
    end
  end
  
  module InstanceMethods
    def create_or_update_with_moderated_check *args
      if valid? && new_record? && @has_moderated_updating != true
        self.to_moderation_created(self.class.moderated_create_options)
        true
      else
        create_or_update_without_moderated_check *args
      end
    end

    def destroy_with_moderated_check *args
      if @has_moderated_updating == true
        destroy_without_moderated_check *args
      else
        to_moderation_destroyed
        true
      end
    end

    def to_moderation_destroyed
      Moderation.create!({
        :moderatable_type => self.class.to_s,
        :moderatable_id => self.id,
        :attr_name => "-",
        :attr_value => "destroy"
      })
    end
    
    def to_moderation_created options
      assocs = []
      
      unless options.blank?
        unless options[:with_associations].blank?
          if options[:with_associations] == :all
            assocs = self.class.reflections.keys.reject do |r|
              r == :moderations
            end
          else
            assocs = options[:with_associations]
            assocs = [assocs] unless assocs.respond_to?("[]")
          end
        end
      end

      assoc_attrs = {}
      assocs.each do |assoc|
        one_assoc = []
        self.send(assoc).each do |m|
          if m.new_record?
            one_assoc.push(m.attributes)
          else
            one_assoc.push(m.id)
          end
        end
        assoc_attrs[assoc] = one_assoc unless one_assoc.empty?
      end

      attr_value = {
        :main_model => self.attributes,
        :associations => assoc_attrs
      }
      
      Moderation.create!({
        :moderatable_type => self.class.to_s,
        :moderatable_id => self.id,
        :attr_name => "-",
        :attr_value => attr_value.to_yaml
      })
    end
    
    def to_moderation
      moderations = []
      self.changes.each_pair do |att_name, values|
        att_name = att_name.to_s
        next if values[1].blank?
        if self.class.moderated_attributes.include?(att_name)
          moderations.push(Moderation.create!({
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

ActiveRecord::Base.send :include, HasModerated
