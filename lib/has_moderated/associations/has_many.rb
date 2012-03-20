module HasModerated
  module Associations
    module HasMany
      module ClassMethods
        protected
          def moderate_has_many_association(assoc)
            after_initialize do
              self.moderate_collection_association(assoc)
            end
          end
      end
    end
  end
end