require 'ostruct'
module HasModerated
  module Preview
    module Saveable
      def update_moderation
        if @based_on_moderation.present?
          data = @based_on_moderation.parsed_data
        
          # attributes
          data[:attributes] ||= Hash.new
          @has_moderated_fake_attributes.each_pair do |key, value|
            if value != @attributes_initial[key]
              data[:attributes][key.to_s] = value
            end
          end
          
          @based_on_moderation.data = data
          @based_on_moderation.save
        end
      end
    end
    
    module FakeRecord
      def fake!(based_on_model, based_on_moderation)
        @based_on_model = based_on_model
        @based_on_moderation = based_on_moderation
        freeze
      end
    end
    
    def self.resolve_record(record, cache)
      return nil if record.blank?
      idx = cache.index(record)
      if idx && idx.present?
        cache[idx] # the difference is that the one in cache is frozen for sure
      else
        cache.push(from_live(record, nil, false, cache))
        cache.last
      end
    end
    
    def self.from_live(record, moderation = nil, saveable = false, object_cache = [])
      return nil if record.blank?
      obj = record
      eigenclass = (class << obj ; include FakeRecord ; self ; end)
      obj.fake!(record.class, moderation)
      
      # attributes
      changed_attributes = Hash.new
      record.previous_changes.each_pair do |attr_name, values|
        changed_attributes[attr_name] = values[0]
      end
      obj.instance_variable_set(:@changed_attributes, changed_attributes)
      
      # saveable
      if saveable
        obj.instance_variable_set(:@attributes_initial, obj.instance_variable_get(:@attributes).dup)
        eigenclass.send(:include, Saveable)
        obj.instance_variable_set(:@has_moderated_fake_attributes, Hash.new)
        obj.attributes.keys.each do |attr_name|
          eigenclass.send(:define_method, "#{attr_name}=") do |value|
            @has_moderated_fake_attributes[attr_name.to_s] = value
          end
        end
      end
      
      # associations
      object_cache.push(obj)
      has_moderated_fake_associations = HashWithIndifferentAccess.new
      record.class.reflections.values.reject{|s| s.name.to_sym == :moderations}.each do |reflection|
        if reflection.macro == :has_one || reflection.macro == :belongs_to
          has_moderated_fake_associations[reflection.name] = resolve_record(record.send(reflection.name), object_cache)
        elsif reflection.collection?
          has_moderated_fake_associations[reflection.name] = record.send(reflection.name).map{|r| resolve_record(r, object_cache)}
        end
      end
      
      obj.instance_variable_set(:@has_moderated_fake_associations, has_moderated_fake_associations.freeze)
      eigenclass.class_eval do
        def association(name)
          OpenStruct.new(:reader => @has_moderated_fake_associations[name].freeze)
        end
      end
      
      obj
    end
  end
end