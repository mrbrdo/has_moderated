module HasModerated
  module Common
    def self.included(base)
      base.send :include, InstanceMethods
    end
    
    def self.init(klass)
      unless klass.class_variable_defined? "@@moderation_disabled"
        klass.class_eval do
          attr_accessor :moderation_disabled
          @@moderation_disabled = false
        end  
        HasModerated::Adapters::Proxy::add_moderations_association klass
      end
    end
    
    def self.try_without_moderation rec
      # TODO: fix this, this method should only be avail. to moderated models
      if rec.respond_to?(:moderation_disabled)
        rec.without_moderation(true) { |rec| yield(rec) }
      else
        yield(rec)
      end
    end

    # calls user hooks for creation of a new moderation
    def self.call_creating_hook model, moderation
      #todo use model.class.moderation_hooks[:creating_moderation]
      if model.class.respond_to?(:moderation_hooks)
        model.class.moderation_hooks[:creating] ||= []
        model.class.moderation_hooks[:creating].each do |hook|
          model.instance_exec moderation, &hook
        end
      end
    end
    
    module InstanceMethods
      def without_moderation(do_disable = true)
        raise "moderation already disabled - illegal nesting" if self.moderation_disabled && do_disable
        self.moderation_disabled = true if do_disable
        yield(self)
        self.moderation_disabled = false if do_disable
      end
      
      def get_moderation_attributes
        HasModerated::Adapters::Proxy::get_default_moderation_attributes(self)
      end
      
      def create_moderation_with_hooks!(*args)
        m = self.moderations.build(:data => args.first)
        HasModerated::Common::call_creating_hook(self, m)
        m.save!
        m
      end
      
      def add_associations_moderated assocs_data
        # convert associations data so it can be serialized
        assocs_processed = Hash.new
        assocs_data.each_pair do |assoc_name, assoc_data_array|
          assocs_processed[assoc_name] = []
          assoc_data_array.each do |assoc_data|
            # convert assoc data to either ID or, if it's a new record, hash of its attributes
            pdata = HasModerated::Adapters::Proxy::hashize_association(self, assoc_name, assoc_data)
            assocs_processed[assoc_name].push(pdata)
          end
        end
        
        # create moderation for adding the associations and return it
        moderations = []
        unless assocs_processed.empty?
          moderations.push(create_moderation_with_hooks!(
              :associations => assocs_processed
            ))
        end

        moderations
      end
      
      # moderate removing associations
      def delete_associations_moderated(assocs)
        moderations = []
        unless assocs.empty?
          moderations.push(create_moderation_with_hooks!(
              :delete_associations => assocs
            ))
        end

        moderations
      end
    end
  end
end