module HasModerated
  module ModerationModel
    def parsed_data
      @parsed_data ||= YAML::load(data)
    end
    
    def apply
      if create?
        record = HasModerated::ModeratedCreate::ApplyModeration::apply(moderatable_type.constantize, parsed_data)
      else
        record = moderatable
        if record
          record = HasModerated::ModeratedAttributes::ApplyModeration::apply(record, parsed_data)
          record = HasModerated::Associations::Base::ApplyModeration::apply(record, parsed_data)
          record = HasModerated::ModeratedDestroy::ApplyModeration::apply(record, parsed_data)
        end
      end
      record
    end
    
    def accept_changes(record)
      if record
        HasModerated::Common::try_without_moderation(record) do
          # don't run validations on save (were already ran when moderation was created)
          record.save(:validate => false)
        end
      end
      record
    end
    
    def accept
      record = apply
      accept_changes(record)
      self.destroy
      record
    end

    def discard
      if moderatable_type
        klass = moderatable_type.constantize
        klass.moderatable_discard(self) if klass.respond_to?(:moderatable_discard)
      end
      self.destroy
    end
    
    def live_preview
      ActiveRecord::Base.transaction do
        record = accept
        yield(record)
        raise ActiveRecord::Rollback
      end
      nil
    end
    
    def preview
      fake_record = nil
      live_preview do |record|
        fake_record = HasModerated::Preview::from_live(record)
      end
      fake_record
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