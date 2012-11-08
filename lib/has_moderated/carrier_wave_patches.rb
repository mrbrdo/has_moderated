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
          # use full_filename so versions work properly
          basename = begin
            uploader.send(:full_filename, ::File::basename(identifier))
          rescue
            ::File::basename(identifier)
          end
          path = ::File::join([::File::dirname(identifier),
            basename])
          ::CarrierWave::HasModeratedTempFile.new(path)
        else
          retrieve_without_moderation_preview!(identifier)
        end
      end
      alias_method_chain :retrieve!, :moderation_preview
    end
  end
end
