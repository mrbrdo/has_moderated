module HasModerated
  module Common
    def self.included(base)
      base.send :include, InstanceMethods
    end
    
    module InstanceMethods
      def create_moderation_with_hooks!(*args)
        m = Moderation.new(*args)
        HasModerated::Common::call_creating_hook(self, m)
        m.save!
        m
      end
      
      def moderatable_updating
        self.has_moderated_updating = true
        yield(self)
        self.has_moderated_updating = false
      end
      
      def get_moderation_attributes(model)
        if model.respond_to?(:moderatable_hashize)
          model.moderatable_hashize
        else
          model.attributes
        end
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
      if model.class.respond_to?(:moderation_creating_hook)
        model.instance_exec moderation, &(model.class.moderation_creating_hook)
      end
    end
  end
end