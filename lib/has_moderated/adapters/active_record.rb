# everything that does with activerecord should be here.
# use a wrapper that calls stuff from here, so that impl. can be switched eg with mongomapper
# also write test that if one attr is moderated and one is not, the unmoderated one must still save immediately!

module HasModerated
  module Adapters
    module ActiveRecord
      # AR specific
      def self.foreign_key(reflection)
        if reflection.respond_to?(:foreign_key)
          reflection.foreign_key
        else # Rails < v3.1
          reflection.primary_key_name
        end
      end
      
      # General
      def self.add_moderations_association(klass)
        klass.class_eval do
          has_many :moderations, :as => :moderatable, :dependent => :destroy
        end
      end
      
      def self.get_default_moderation_attributes(record)
        record.attributes
      end
      
      def self.hashize_association(from_record, assoc_name, m)
        # todo
        through_assocs = {}
        from_record.class.reflections.keys.each do |assoc|
          join_model = from_record.class.reflections[assoc.to_sym].options[:through]
          if join_model
            join_model = join_model.to_sym
            through_assocs[join_model] ||= []
            through_assocs[join_model].push(assoc)
          end
        end
        
        assoc = nil
        if m.class == Fixnum
          assoc = m
        elsif m.kind_of? Hash  # already a hash (for has_many :through association)
          assoc = m
        elsif m.respond_to?(:get_moderation_attributes) && m.new_record?
          assoc = m.get_moderation_attributes
        elsif m.respond_to?(:get_moderation_attributes)
          assoc = m.id
        else
          raise "don't know how to convert #{m.class} to hash"
        end
        
        if through_assocs[assoc_name.to_sym] # TODO !
          assoc[:associations] = get_assocs_for_moderation(:all, m)
        end
        assoc
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
              one_assoc.push(m.get_moderation_attributes)
            else
              one_assoc.push(m.id)
            end
            if through_assocs[assoc.to_sym]
              one_assoc.last[:associations] = get_assocs_for_moderation(:all, m)
            end
          end
          assoc_attrs[assoc] = one_assoc unless one_assoc.empty?
        end

        assoc_attrs
      end
    end
  end
end