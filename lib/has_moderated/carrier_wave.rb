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
      begin
        dirname = File.expand_path("..", value)
        filename = File.basename(value)
        # must delete versions as well, the filename of versions
        # should be version_filename.ext, where version is the name
        # of the version (e.g. thumb_test.png)
        r = Regexp.new("#{filename}\\Z")
        Dir.foreach(dirname) do |f|
          if f =~ r
            FileUtils.rm("#{dirname}/#{f}") # remove temp file
          end
        end
        FileUtils.rmdir(File.expand_path("..", value)) # will only remove folder if empty
      rescue
      end
    end

    module ClassMethods
      # use class method because we only operate on hash parameters, not with a real record
      # here we can delete the photo from tmp
      def moderatable_discard(moderation)
        value = moderation.interpreted_value
        if moderation.attr_name == "-" && value && value.respond_to?("[]") &&
          value[:main_model] && value[:main_model][:photo_tmp_file]
          value = value[:main_model][:photo_tmp_file]
        elsif moderation.attr_name != "photo_tmp_file"
          return # we dont want to process anything else than the above
        end
          
        unless value.blank?
          HasModerated::CarrierWave::photo_tmp_delete(value)
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
        self.photo = File.open(value)
        HasModerated::CarrierWave::photo_tmp_delete(value)
      end
      
      def store_photo_with_moderation!
        is_moderated = self.class.respond_to?(:moderated_attributes) &&
          self.class.moderated_attributes.include?("carrierwave_photo")
        if self.has_moderated_updating || !is_moderated || !self.photo_changed?
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
          self.class.moderated_attributes.include?("carrierwave_photo")
        if self.has_moderated_updating || !is_moderated || !self.photo_changed?
          write_photo_identifier_without_moderation
        end
      end
    end
  end
end