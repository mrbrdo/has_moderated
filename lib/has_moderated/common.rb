module HasModerated
  module Common
    def self.included(base)
      base.send :include, InstanceMethods
    end
    
    def self.init(klass)
      # TODO: do this only once
      klass.class_eval do
        attr_accessor :moderation_disabled
        @@moderation_disabled = false
        has_many :moderations, :as => :moderatable, :dependent => :destroy
      end
    end
    
    def self.foreign_key(reflection)
      if reflection.respond_to?(:foreign_key)
        reflection.foreign_key
      else # Rails < v3.1
        reflection.primary_key_name
      end
    end
    
    def self.try_disable_moderation rec
      # TODO: fix this, this method should only be avail. to moderated models
      if rec.respond_to?(:moderation_disabled)
        rec.disable_moderation(true) { |rec| yield(rec) }
      else
        yield(rec)
      end
    end
    
    module InstanceMethods
      
      def disable_moderation(disable_moderation = true)
        raise "moderation already disabled - illegal nesting" if self.moderation_disabled && disable_moderation
        self.moderation_disabled = true if disable_moderation
        yield(self)
        self.moderation_disabled = false if disable_moderation
      end
      
      def get_moderation_attributes
        self.attributes
      end
      
      def create_moderation_with_hooks!(*args)
        m = self.moderations.build(*args)
        HasModerated::Common::call_creating_hook(self, m)
        m.save!
        m
      end
      
      ##
      
      
      
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
              one_assoc.push(from_record.get_moderation_attributes(m))
            else
              one_assoc.push(m.id)
            end
            if through_assocs[assoc_name.to_sym]
              one_assoc.last[:associations] = HasModerated::Common::get_assocs_for_moderation(through_assocs[assoc_name.to_sym], m)
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
      
      def delete_associations_moderated(assocs)
        moderations = []
        if !assocs.empty?
          moderations.push(create_moderation_with_hooks!({
              :moderatable_type => self.class.to_s,
              :moderatable_id => self.id,
              :attr_name => "-",
              :attr_value => { :delete_associations => assocs }
            }))
        end

        moderations
      end
    end
    
    def self.get_assocs_for_moderation assocs, from_record = nil
      from_record ||= self
      return if assocs.blank?

      if assocs == :all
        assocs = from_record.class.reflections.keys.reject do |r|
          r == :moderations
        end
      end
      
      assocs = [assocs] unless assocs.respond_to?("[]")

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
            one_assoc.push(from_record.get_moderation_attributes(m))
          else
            one_assoc.push(m.id)
          end
          if through_assocs[assoc.to_sym]
            one_assoc.last[:associations] = get_assocs_for_moderation(through_assocs[assoc.to_sym], m)
          end
        end
        assoc_attrs[assoc] = one_assoc unless one_assoc.empty?
      end

      assoc_attrs
    end
    
    def self.call_creating_hook model, moderation
      #todo use model.class.moderation_hooks[:creating_moderation]
      if model.class.respond_to?(:moderation_creating_hook)
        model.instance_exec moderation, &(model.class.moderation_creating_hook)
      end
    end
  end
end