module HasModerated
  module Associations
    module Collection
      module AssociationPatches
        # moderate adding associations
        def add_to_target_with_moderation record
          if owner.new_record? || owner.moderation_disabled
            add_to_target_without_moderation record
          else
            HasModerated::Associations::Base::CreateModeration::add_associations_moderation(owner, self.reflection.name => [record])
            record
          end
        end

        # moderate removing associations
        def delete_records_with_moderation(records, method) # method comes from :dependent => :destroy
          if owner.new_record? || owner.moderation_disabled
            delete_records_without_moderation(records, method)
          else
            #todo only care for records which are already in database
            record_ids = records.map(&:id)
            owner.delete_associations_moderated(self.reflection.name => record_ids)
          end
        end
      end
      
      module ClassMethods
        protected
          def has_moderated_collection_association(reflection)
            after_initialize do
              assoc = self.association(reflection.name)
              # check association type
              if reflection.collection?
                # patch methods to moderate changes
                assoc.class.send(:include, AssociationPatches)
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
  end
end