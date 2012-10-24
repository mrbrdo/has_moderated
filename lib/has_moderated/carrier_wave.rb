require 'fileutils'
module HasModerated
  module CarrierWave

    def self.included(base)
      base.send :extend, ClassMethods
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
      def has_moderated_carrierwave_field field_names
        base = self
        base.send :include, InstanceMethods

        cattr_accessor :moderated_carrierwave_fields

        field_names = [field_names] unless field_names.kind_of? Array

        field_names.each do |field_name|
          field_name = field_name.to_s
          self.moderated_carrierwave_fields ||= []
          self.moderated_carrierwave_fields.push(field_name)

          base.send :define_method, "#{field_name}_tmp_file=" do |tmp_filename|
            if @has_moderated_preview != true
              self.send("#{field_name}=", File.open(tmp_filename))
              HasModerated::CarrierWave::photo_tmp_delete(tmp_filename)
            elsif tmp_filename.present?
              # preview
              self.singleton_class.class_eval do
                define_method :"#{field_name}_with_preview" do |*args, &block|
                  uploader = send(:"#{field_name}_without_preview", *args, &block)
                  unless uploader.frozen?
                    uploader.instance_variable_set(:@file,
                      ::CarrierWave::SanitizedFile.new(
                        File.open(tmp_filename, "rb")))
                    uploader.freeze
                  end
                  uploader
                end
                define_method :"#{field_name}?" do
                  true
                end
                define_method :"#{field_name}_url" do
                  send("#{field_name}").url
                end
                alias_method_chain :"#{field_name}", :preview
              end
            end
          end

          base.send :define_method, "store_#{field_name}_with_moderation!" do
            is_moderated = self.class.respond_to?(:moderated_attributes) &&
              self.class.moderated_attributes.include?(field_name)
            if !is_moderated || self.moderation_disabled || !self.send("#{field_name}_changed?")
              self.send("store_#{field_name}_without_moderation!")
            else
              self.create_moderation_with_hooks!({
                :attributes => {
                  "#{field_name}_tmp_file" => self.send(field_name).file.file
                }
              })
            end
          end

          base.send :define_method, "write_#{field_name}_identifier_with_moderation" do
            is_moderated = self.class.respond_to?(:moderated_attributes) &&
              self.class.moderated_attributes.include?(field_name)
            if !@has_moderated_preview &&
              (!is_moderated || self.moderation_disabled || !self.send("#{field_name}_changed?"))
              self.send("write_#{field_name}_identifier_without_moderation")
            end
          end

          base.alias_method_chain :get_moderation_attributes, :carrierwave unless base.instance_methods.include?("get_moderation_attributes_without_carrierwave")
          base.alias_method_chain "store_#{field_name}!", :moderation
          base.alias_method_chain "write_#{field_name}_identifier", :moderation
        end
      end

      # use class method because we only operate on hash parameters, not with a real record
      # here we can delete the photo from tmp
      def moderatable_discard(moderation, options)
        return if options[:preview_mode]
        value = moderation.parsed_data

        moderated_carrierwave_fields.each do |field_name|
          if value.kind_of? Hash
            if value.has_key?(:create) && value[:create].has_key?(:attributes)
              value = value[:create]
            end
            if value.has_key?(:attributes) && value[:attributes].has_key?("#{field_name}_tmp_file")
              value = value[:attributes]["#{field_name}_tmp_file"]
              if value.present?
                HasModerated::CarrierWave::photo_tmp_delete(value)
              end
            else
              return # we dont want to process anything else than the above
            end
          end
        end
      end
    end

    module InstanceMethods
      def get_moderation_attributes_with_carrierwave
        attrs = get_moderation_attributes_without_carrierwave
        self.class.moderated_carrierwave_fields.each do |field_name|
          attrs = attrs.merge({
            "#{field_name}_tmp_file" => self.send(field_name).file.file
          }) if self.send(field_name) && self.send(field_name).file
        end
        attrs
      end
    end
  end
end
