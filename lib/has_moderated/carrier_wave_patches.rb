require 'carrierwave'
module ::CarrierWave
  class HasModeratedTempFile < SanitizedFile
    def initialize(file)
      super(file)
    end

    def move_to(*args)
      self
    end

    def copy_to(*args)
      self
    end

    def delete(*args)
      false
    end
  end

  module Storage
    class File
      def retrieve_with_moderation_preview!(identifier)
        tmp_path = Pathname.new(Rails.public_path).join(@uploader.class.store_dir).join("tmp").to_s

        if identifier.try(:start_with?, tmp_path)
          ::CarrierWave::HasModeratedTempFile.new(identifier)
        else
          retrieve_without_moderation_preview!(identifier)
        end
      end
      alias_method_chain :retrieve!, :moderation_preview
    end
  end
end
