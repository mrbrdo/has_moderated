module HasModerated
  module Associations
    module HasMany
      def self.add_assoc_to_record(to, record, reflection)
        fk = HasModerated::Adapters::ActiveRecord::foreign_key(reflection).try(:to_s)
        field = if !reflection.options[:as].blank?
          # todo: extract
          reflection.options[:as].to_s
        elsif !fk.blank?
          results = record.class.reflections.reject do |assoc_name, assoc|
            !(HasModerated::Adapters::ActiveRecord::foreign_key(assoc).try(:to_s) == fk)
          end
          if results.blank?
            raise "Please set foreign_key for both belongs_to and has_one/has_many!"
          end
          results.first[1].name.to_s
        else
          to.class.to_s.underscore
        end
        HasModerated::Common::try_without_moderation(record) do
          record.send(field + "=", to)
        end
      end
      
      def self.delete_assoc_from_record(from, assoc_id, reflection)
        return unless from && assoc_id
        klass = reflection.class_name.constantize
        
        if reflection.macro == :has_and_belongs_to_many || !reflection.options[:through].blank? || reflection.macro == :has_many
          from.send(reflection.name).delete(klass.find_by_id(assoc_id))
        else
          raise "Cannot delete association for this type of associations!"
        end
      end
      
      module ClassMethods
        protected
          def has_moderated_has_many_association(reflection)
            # lazy load
            self.send :extend, HasModerated::Associations::Collection::ClassMethods
            has_moderated_collection_association(reflection)
          end
      end
    end
  end
end