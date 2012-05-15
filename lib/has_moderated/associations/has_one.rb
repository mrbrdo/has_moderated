module HasModerated
  module Associations
    module HasOne
      module AssociationPatches
        def replace_with_moderation(record, save = true)
          # TODO: code duplication
          if owner.new_record? || owner.moderation_disabled
            replace_without_moderation record
          else
            if record.blank? # use dummy value so it's not nil
              owner.delete_associations_moderated(self.reflection.name => [1])
            else
              owner.add_associations_moderated(self.reflection.name => [record])
            end
            record
          end
        end
      end # module
      
      def self.add_assoc_to_record(*args)
        # same as HasMany
        HasModerated::Associations::HasMany::add_assoc_to_record(*args)
      end
      
      def self.delete_assoc_from_record(from, assoc_id, reflection)
        from.send("#{reflection.name}=", nil)
        from.save # TODO necessary?
      end
      
      module ClassMethods
        protected
          def has_moderated_has_one_association(reflection)
            after_initialize do
              assoc = self.association(reflection.name)
              # check association type
              if !reflection.collection?
                # patch methods to moderate changes
                assoc.class_eval do
                  include AssociationPatches
                  alias_method_chain :replace, :moderation
                end
              else
                raise "called on an invalid association"
              end
            end
          end
      end
    end
  end
end