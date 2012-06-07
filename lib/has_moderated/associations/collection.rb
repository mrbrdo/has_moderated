module HasModerated
  module Associations
    module Collection
      module AssociationPatches
        # moderate adding associations
        def add_to_target_with_moderation record
          # If create is moderated, then add assoc. record normally, as create moderation
          # will prevent AR from creating the assoc. record in DB.
          # However, if create is not moderated, and owner is a new record,
          # then AR will create the assoc. record on
          # owner.save. In this case, add moderation as association now - see
          # create_moderation_with_hooks - the moderation will be saved when owner is saved,
          # so AR will properly set moderatable_id.
          create_moderated_and_new = owner.new_record? && owner.class.respond_to?(:moderated_create_options)
          if create_moderated_and_new || owner.moderation_disabled
            add_to_target_without_moderation record
          else
            owner.add_associations_moderated(self.reflection.name => [record])
            record
          end
        end

        # moderate removing associations
        def delete_records_with_moderation(records, method) # method comes from :dependent => :destroy
          if owner.new_record? || owner.moderation_disabled
            delete_records_without_moderation(records, method)
          else
            # TODO only care for records which are already in database
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
                # avoid multiple patch problem and still work for tests
                if assoc.respond_to?(:add_to_target_without_moderation)
                  assoc.class_eval do
                    alias_method :add_to_target, :add_to_target_without_moderation
                  end
                end
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
      
      module AssociationHelpers
        def self.add_assoc_to_record_habtm_hmt(target, assoc_record, reflection)
          field = if reflection.options[:join_table].present?
            join_table = reflection.options[:join_table].to_s
            results = assoc_record.class.reflections.reject do |assoc_name, assoc|
              !(assoc.options[:join_table] && assoc.options[:join_table].to_s == join_table)
            end
            if results.count != 1
              raise "has_moderated: Cannot determine join table for a Habtm association! Are you missing has_and_belongs_to_many in one of your models?"
            end
            results.first[1].name.to_s
          elsif reflection.options[:through].present?
            through_model = reflection.options[:through].to_s
            results = assoc_record.class.reflections.reject do |assoc_name, assoc|
              !(assoc.options[:through] && assoc.options[:through].to_s == through_model)
            end
            if results.count != 1
              raise "has_moderated: Cannot determine correct association for a has_many :through association!"
            end
            results.first[1].name.to_s
          else
            raise "has_moderated: Cannot determine association details!"
          end
          assoc_record.send(field) << target
        end

        def self.add_assoc_to_record_hm(to, record, reflection)
          fk = HasModerated::ActiveRecordHelpers::foreign_key(reflection).try(:to_s)
          field = if !reflection.options[:as].blank?
            reflection.options[:as].to_s
          elsif !fk.blank?
            all_keys = []
            results = record.class.reflections.reject do |assoc_name, assoc|
              all_keys.push(HasModerated::ActiveRecordHelpers::foreign_key(assoc).try(:to_s))
              !(HasModerated::ActiveRecordHelpers::foreign_key(assoc).try(:to_s) == fk)
            end
            if results.blank?
              raise "Please set foreign_key for both belongs_to and has_one/has_many! fk: #{fk}, keys: #{all_keys.to_yaml}"
            end
            results.first[1].name.to_s
          else
            to.class.to_s.underscore # TODO hardcoded, fix
          end
          HasModerated::Common::try_without_moderation(record) do
            record.send(field + "=", to)
          end
        end

        def self.add_assoc_to_record(to, record, reflection)
          if reflection.macro == :has_and_belongs_to_many || !reflection.options[:through].blank?
            add_assoc_to_record_habtm_hmt(to, record, reflection)
          else
            add_assoc_to_record_hm(to, record, reflection)
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
      end
    end
  end
end