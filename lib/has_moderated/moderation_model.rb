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
  end
end