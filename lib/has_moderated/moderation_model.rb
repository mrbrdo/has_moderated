module HasModerated
  module ModerationModel
    def self.included(base)
      base.class_eval do
        alias_method_chain :destroy, :moderation_callbacks
        cattr_accessor :moderation_disabled
        self.moderation_disabled = false

        def self.without_moderation(do_disable = true)
          already_disabled = self.moderation_disabled
          self.moderation_disabled = true if do_disable
          begin
            retval = yield(self)
          ensure
            self.moderation_disabled = false if do_disable && !already_disabled
          end
          retval
        end
      end
    end

    def parsed_data
      @parsed_data ||= YAML::load(data)
    end

    def apply(save_opts = Hash.new, preview_mode = false)
      if create?
        record = HasModerated::ModeratedCreate::ApplyModeration::apply(moderatable_type.constantize, parsed_data, save_opts, preview_mode)
      else
        record = moderatable
        if record
          record = HasModerated::ModeratedAttributes::ApplyModeration::apply(record, parsed_data, preview_mode)
          record = HasModerated::Associations::Base::ApplyModeration::apply(record, parsed_data, save_opts, preview_mode)
          record = HasModerated::ModeratedDestroy::ApplyModeration::apply(record, parsed_data)
        end
      end
      record
    end

    def accept_changes(record, save_opts = Hash.new)
      if record
        Moderation.without_moderation do
          # run validations (issue #12)
          record.save!(save_opts)
        end
      end
      record
    end

    def accept!(save_opts = Hash.new, preview_mode = false)
      record = apply(save_opts, preview_mode)
      accept_changes(record, save_opts)
      self.destroy(:preview_mode => preview_mode)
      record
    end

    def accept(save_opts = Hash.new, preview_mode = false)
      begin
        accept!(save_opts, preview_mode)
        true
      rescue
        false
      end
    end

    def destroy_with_moderation_callbacks(*args)
      options = args.first || Hash.new
      if moderatable_type
        klass = moderatable_type.constantize
        klass.moderatable_discard(self, options) if klass.respond_to?(:moderatable_discard)
      end
      destroy_without_moderation_callbacks
    end

    def discard
      destroy_with_moderation_callbacks
    end

    def live_preview
      # absolutely no point to preview a destroy moderation
      if destroy? && parsed_data.keys.count == 1
        yield(nil)
        return nil
      end

      self.transaction do
        record = accept!({ :perform_validation => false }, true)
        yield(record)
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
      # Ruby 1.8 will unfreeze when doing ActiveRecord::Rollback
      # Only necessary to re-freeze for 1.8, associations stay frozen as normal
      fake_record.freeze
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
