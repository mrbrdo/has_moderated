module HasModerated
  module Associations
    module HasMany
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