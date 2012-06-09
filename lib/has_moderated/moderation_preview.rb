require 'ostruct'
module HasModerated
  module Preview
    module Saveable
      def update_moderation
        if @based_on_moderation.present?
          data = @based_on_moderation.parsed_data
        
          # attributes
          data[:attributes] ||= Hash.new
          @attributes.each_pair do |key, value|
            if value != @attributes_initial[key]
              data[:attributes][key.to_s] = value
            end
          end
          
          @based_on_moderation.data = data
          @based_on_moderation.save
        end
      end
    end
    
    class FakeRecord
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Dirty
      
      attr_accessor :attributes
      
      def initialize(based_on_model, based_on_moderation)
        @based_on_model = based_on_model
        @based_on_moderation = based_on_moderation
      end
      
      def persisted?
        false
      end
      
      def attribute name
        attributes[name]
      end
      
      def id
        attributes["id"]
      end
      
      def to_s
        "#<HasModerated::Fake#{@based_on_model.to_s}>"
      end
      
      def inspect
        to_s.chomp(">") +
          instance_variables.map{|name| " #{name}=#{instance_variable_get(name)}"}.join(",") +
          ", reflections.keys => [" + reflections.keys.map{|s| ":#{s}"}.join(", ")+ "]>"
      end
    end
    
    def self.create_fake_association(attr_name, value, target)
      target.send(:define_method, attr_name) do
        value
      end
    end
    
    def self.resolve_record(record, cache)
      return nil if record.blank?
      cache[record.class] ||= Hash.new
      if cache[record.class][record.id].present?
        cache[record.class][record.id]
      else
        cache[record.class][record.id] = from_live(record, nil, false, cache)
      end
    end
    
    def self.from_live(record, moderation = nil, saveable = false, object_cache = nil)
      return nil if record.blank?
      obj = FakeRecord.new(record.class, moderation)
      eigenclass = (class << obj ; self ; end)
      
      # attributes
      obj.instance_variable_set(:@attributes, record.instance_variable_get(:@attributes))
      changed_attributes = Hash.new
      record.previous_changes.each_pair do |attr_name, values|
        changed_attributes[attr_name] = values[0]
      end
      obj.instance_variable_set(:@changed_attributes, changed_attributes)
      
      # saveable
      if saveable
        obj.instance_variable_set(:@attributes_initial, record.instance_variable_get(:@attributes).dup)
        eigenclass.send(:include, Saveable)
        obj.attributes.keys.each do |attr_name|
          eigenclass.send(:define_method, "#{attr_name}=") do |value|
            self.attributes[attr_name.to_s] = value
          end
        end
      end
      
      # associations
      object_cache ||= Hash.new
      object_cache[record.class] ||= Hash.new
      object_cache[record.class][record.id] = obj
      eigenclass.send(:define_method, :reflections) do
        record.class.reflections.reject{|k,v| k.to_sym == :moderations}
      end
      record.class.reflections.values.reject{|s| s.name.to_sym == :moderations}.each do |reflection|
        if reflection.macro == :has_one || reflection.macro == :belongs_to
          create_fake_association(
            reflection.name,
            resolve_record(record.send(reflection.name), object_cache),
            eigenclass)
        elsif reflection.collection?
          create_fake_association(
            reflection.name,
            record.send(reflection.name).map{|r| resolve_record(r, object_cache)},
            eigenclass)
        end
      end
      
      obj
    end
  end
end