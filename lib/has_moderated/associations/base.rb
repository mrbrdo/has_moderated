module HasModerated
  module Associations
    module Base
      module ClassMethods
        def has_moderated_association(*args)
          assoc_names = []
          args = [args] unless args.respond_to?("[]")

          unless args.blank?
            if args.include?(:all)
              assoc_names = self.reflections.keys.reject do |r|
                r == :moderations
              end
            else
              assoc_names = args
            end
          end
          
          assocs = assoc_names.map { |name| self.reflections[name] }
          
          assocs.each do |assoc|
            case assoc.macro
              when :has_many then
                moderate_has_many_association(assoc)
              else raise "don't know how to moderate association macro #{assoc.macro}"
            end
          end
        end
      end
      
      def moderate_collection_association(assoc)
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
          def assoc.delete_records_with_moderation(records, method) # method comes from :dependent => :destroy
            if !owner.new_record? && !owner.has_moderated_updating
              #todo only care for records which are already in database
              record_ids = records.map(&:id)
              owner.delete_associations_moderated(self.reflection.name => record_ids)
            else
              delete_records_without_moderation(records, method)
            end
          end
          assoc.class_eval do
            alias_method_chain :add_to_target, :moderation
            alias_method_chain :delete_records, :moderation
          end
        else
          raise "called on an invalid association"
        end
      end
    end
  end
end