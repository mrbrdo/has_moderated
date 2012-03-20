module HasModerated
  module ModeratedAssociations
    module ClassMethods
      def has_moderated_association *args
        assocs = []

        unless args.blank?
          if args == [:all]
            assocs = self.reflections.keys.reject do |r|
              r == :moderations
            end
          else
            assocs = args
            assocs = [assocs] unless assocs.respond_to?("[]")
          end
        end

        #TODO: should add to some class var and clean duplicates

        after_initialize do
          assocs.each do |assoc_name|
            assoc = self.association(assoc_name)
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
              def assoc.replace_with_moderation(record, save = true)
                if !owner.new_record? && !owner.has_moderated_updating
                  #TODO: add moderation
                  owner.add_associations_moderated(self.reflection.name => [record])
                  record
                else
                  replace_without_moderation record
                end
              end
              assoc.class_eval do
                alias_method_chain :replace, :moderation
              end
            end
          end
        end
      end
    end
    
    module InstanceMethods
      
    end
  end
end