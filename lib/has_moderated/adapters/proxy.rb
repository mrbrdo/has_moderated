module HasModerated
  module Adapters
    module Proxy
      def self.add_moderations_association(klass)
        if klass.superclass.to_s == "ActiveRecord::Base"
          Adapters::ActiveRecord::add_moderations_association(klass)
        end
      end
      
      def self.get_default_moderation_attributes(record)
        if record.class.superclass.to_s == "ActiveRecord::Base"
          Adapters::ActiveRecord::get_default_moderation_attributes(record)
        end
      end
      
      def self.hashize_association(record, assoc_name, m)
        if record.class.superclass.to_s == "ActiveRecord::Base"
          Adapters::ActiveRecord::hashize_association(record, assoc_name, m)
        end
      end
    end
  end
end