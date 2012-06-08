module HasModerated
  module ModerationModel
    def parsed_data
      @parsed_data ||= YAML::load(data)
    end
    
    def accept
      HasModerated::ModeratedCreate::ApplyModeration::apply(self, parsed_data)
      HasModerated::ModeratedAttributes::ApplyModeration::apply(self, parsed_data)
      HasModerated::Associations::Base::ApplyModeration::apply(self, parsed_data)
      HasModerated::ModeratedDestroy::ApplyModeration::apply(self, parsed_data)
      self.destroy
    end

    def discard
      if moderatable_type
        klass = moderatable_type.constantize
        klass.moderatable_discard(self) if klass.respond_to?(:moderatable_discard)
      end
      self.destroy
    end
    
    def preview
      ActiveRecord::Base.transaction do
        accept
        yield
        raise ActiveRecord::Rollback
      end
    end
    
    def create?
      parsed_data[:create].present?
    end
    
    def destroy?
      parsed_data[:destroy] == true
    end
    
    def update?
      !(create? || destroy?)
    end
  end
end