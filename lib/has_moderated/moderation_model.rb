module HasModerated
  module ModerationModel
    def parsed_data
      @parsed_data ||= YAML::load(data)
    end
    
    def accept
      loaded_val = parsed_data
      HasModerated::ModeratedCreate::ApplyModeration::apply(self, loaded_val)
      HasModerated::ModeratedAttributes::ApplyModeration::apply(self, loaded_val)
      HasModerated::Associations::Base::ApplyModeration::apply(self, loaded_val)
      HasModerated::ModeratedDestroy::ApplyModeration::apply(self, loaded_val)
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
      HasModerated::ModeratedAttributes::ApplyModeration::apply(self, parsed_data, false)
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