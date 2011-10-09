require 'has_moderated/moderation_model'
require 'has_moderated/carrier_wave'

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
    
    def moderation_creating &block
      cattr_accessor :moderation_creating_hook
      self.moderation_creating_hook = block
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
    
    def has_moderated_association *args
      assocs = []
      
      unless args.blank?
        if args == [:all]
          assocs = self.reflections.keys.reject do |r|
            r == :moderations
          end
        else
          assocs = args
          assocs = [assocs] unless assocs.respond_to?("[]")
        end
      end
      
      #TODO: should add to some class var and clean duplicates
      
      after_initialize do
        assocs.each do |assoc_name|
          assoc = self.association(assoc_name)
          if assoc.reflection.collection?
            def assoc.add_to_target_with_moderation record
              if !owner.new_record? && !owner.has_moderated_updating
                #TODO: add moderation
                owner.add_associations_moderated(self.reflection.name => [record])
                record
              else
                add_to_target_without_moderation record
              end
            end
            assoc.class_eval do
              alias_method_chain :add_to_target, :moderation
            end
          else
            def assoc.replace_with_moderation(record, save = true)
              if !owner.new_record? && !owner.has_moderated_updating
                #TODO: add moderation
                owner.add_associations_moderated(self.reflection.name => [record])
                record
              else
                replace_without_moderation record
              end
            end
            assoc.class_eval do
              alias_method_chain :replace, :moderation
            end
          end
        end
      end
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
    
    def call_creating_hook moderation
      if self.class.respond_to?(:moderation_creating_hook)
        self.instance_exec moderation, &self.class.moderation_creating_hook
      end
    end
    
    def create_moderation_with_hooks!(*args)
      m = Moderation.new(*args)
      call_creating_hook(m)
      m.save!
      m
    end

    def to_moderation_destroyed
      create_moderation_with_hooks!({
        :moderatable_type => self.class.to_s,
        :moderatable_id => self.id,
        :attr_name => "-",
        :attr_value => "destroy"
      })
    end

    def get_assocs_for_moderation options, from_record = nil
      from_record ||= self
      assocs = []
      
      unless options.blank?
        unless options[:with_associations].blank?
          if options[:with_associations] == :all
            assocs = from_record.class.reflections.keys.reject do |r|
              r == :moderations
            end
          else
            assocs = options[:with_associations]
            assocs = [assocs] unless assocs.respond_to?("[]")
          end
        end
      end
      
      # check for through assocs
      assocs = assocs.dup
      through_assocs = {}
      assocs.each do |assoc|
        join_model = from_record.class.reflections[assoc.to_sym].options[:through]
        if join_model
          join_model = join_model.to_sym
          through_assocs[join_model] ||= []
          through_assocs[join_model].push(assoc)
          assocs.push(join_model) unless assocs.include?(join_model)
          #assocs.delete(assoc)
        end
      end

      assoc_attrs = {}
      assocs.each do |assoc|
        one_assoc = []
        assoc_value = from_record.send(assoc)
        # if it's has_one it won't be an array
        assoc_value = [assoc_value] if assoc_value && assoc_value.class != Array
        assoc_value ||= []
        assoc_value.each do |m|
          if m.new_record?
            one_assoc.push(get_moderation_attributes(m))
          else
            one_assoc.push(m.id)
          end
          if through_assocs[assoc.to_sym]
            one_assoc.last[:associations] = get_assocs_for_moderation({ :with_associations => through_assocs[assoc.to_sym] }, m)
          end
        end
        assoc_attrs[assoc] = one_assoc unless one_assoc.empty?
      end

      assoc_attrs
    end
    
    def get_moderation_attributes(model)
      if model.respond_to?(:moderatable_hashize)
        model.moderatable_hashize
      else
        model.attributes
      end
    end
    
    def to_moderation_created options
      assoc_attrs = get_assocs_for_moderation(options)

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

    def add_associations_moderated assocs
      # check for through assocs
      from_record = self
      through_assocs = {}
      from_record.class.reflections.keys.each do |assoc|
        join_model = from_record.class.reflections[assoc.to_sym].options[:through]
        if join_model
          join_model = join_model.to_sym
          through_assocs[join_model] ||= []
          through_assocs[join_model].push(assoc)
        end
      end
      
      assoc_attrs = {}
      assocs.each_pair do |assoc_name, assoc|
        one_assoc = []
        assoc.each do |m|
          if m.class == Fixnum
            one_assoc.push(m)
          elsif m.new_record?
            one_assoc.push(get_moderation_attributes(m))
          else
            one_assoc.push(m.id)
          end
          if through_assocs[assoc_name.to_sym]
            one_assoc.last[:associations] = get_assocs_for_moderation({ :with_associations => through_assocs[assoc_name.to_sym] }, m)
          end
        end
        assoc_attrs[assoc_name] = one_assoc unless one_assoc.empty?
      end
      
      moderations = []
      if !assoc_attrs.empty?
        moderations.push(create_moderation_with_hooks!({
            :moderatable_type => self.class.to_s,
            :moderatable_id => self.id,
            :attr_name => "-",
            :attr_value => { :associations => assoc_attrs }
          }))
      end
      
      moderations
    end
    
    def moderatable_updating
      self.has_moderated_updating = true
      yield(self)
      self.has_moderated_updating = false
    end
  end
end

ActiveRecord::Base.send :include, HasModerated
