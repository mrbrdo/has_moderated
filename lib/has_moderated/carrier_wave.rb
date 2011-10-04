require 'fileutils'
module HasModerated
  module CarrierWave
    
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
      
      base.alias_method_chain :store_photo!, :moderation
      base.alias_method_chain :write_photo_identifier, :moderation
    end  
    
    def self.photo_tmp_delete(value)
      FileUtils.rm(value) # remove temp file
      begin
        FileUtils.rmdir(File.expand_path("..", value)) # will only remove folder if empty
      rescue Errno::ENOTEMPTY
      end
    end

    module ClassMethods
      # use class method because we only operate on hash parameters, not with a real record
      # here we can delete the photo from tmp
      def moderatable_discard(moderation)
        value = moderation.interpreted_value
        if value && value.respond_to?("[]") &&
          value[:main_model] && value[:main_model][:photo_tmp_file]
          HasModerated::CarrierWave::photo_tmp_delete(value[:main_model][:photo_tmp_file])
        end
      end
    end
    
    module InstanceMethods
      attr_accessor :has_moderated_updating # in case this model itself is not moderated
      # maybe autodetect fields that use carrierwave, or specify them
      def moderatable_hashize
        attrs = self.attributes
        attrs = attrs.merge({
          :photo_tmp_file => self.photo.file.file
        }) if self.photo && self.photo.file
      end
    
      def photo_tmp_file=(value)
        self.photo.store!(File.open(value))
        HasModerated::CarrierWave::photo_tmp_delete(value)
      end
      
      def store_photo_with_moderation!
        is_moderated = self.class.respond_to?(:moderated_attributes) &&
          self.class.moderated_attributes.include?("photo")
        if self.has_moderated_updating || !is_moderated
          store_photo_without_moderation!
        else
          self.moderations.create!({
            :attr_name => "photo_tmp_file",
            :attr_value => self.photo.file.file
          })
        end
      end

      def write_photo_identifier_with_moderation
        is_moderated = self.class.respond_to?(:moderated_attributes) &&
          self.class.moderated_attributes.include?("photo")
        if self.has_moderated_updating || !is_moderated
          write_photo_identifier_without_moderation
        end
      end
    end
  end
end