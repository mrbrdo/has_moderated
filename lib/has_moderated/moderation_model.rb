module HasModerated
  module ModerationModel
    def self.included(base)
      base.class_eval do
        alias_method_chain :destroy, :moderation_callbacks
        cattr_accessor :moderation_disabled
        self.moderation_disabled = false

        def self.without_moderation(do_disable = true)
          self.moderation_disabled = true if do_disable
          retval = yield(self)
          self.moderation_disabled = false if do_disable
          retval
        end
      end
    end

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

    def accept_changes(record, save_opts = Hash.new)
      if record
        HasModerated::Common::try_without_moderation(record) do
          # run validations (issue #12)
          record.save!(save_opts)
        end
      end
      record
    end

    def accept!(save_opts = Hash.new)
      record = apply
      accept_changes(record, save_opts)
      self.destroy
      record
    end

    def accept(save_opts = Hash.new)
      begin
        accept!(save_opts)
        true
      rescue
        false
      end
    end

    def destroy_with_moderation_callbacks
      if moderatable_type
        klass = moderatable_type.constantize
        klass.moderatable_discard(self) if klass.respond_to?(:moderatable_discard)
      end
      destroy_without_moderation_callbacks
    end

    def discard
      destroy_with_moderation_callbacks
    end

    def live_preview
      self.transaction do
        accept!(:perform_validation => false)
        yield(self.moderatable)
        raise ActiveRecord::Rollback
      end
      # self.frozen? now became true
      # since we don't actually commit to database, we don't need the freeze
      # only way I found to unfreeze is to dup attributes
      @attributes = @attributes.dup

      nil
    end

    def preview(options = {})
      options[:saveable] ||= false
      fake_record = nil
      live_preview do |record|
        fake_record = HasModerated::Preview::from_live(record, self, options[:saveable])
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
