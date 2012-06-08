require 'ostruct'
module HasModerated
  module Preview
    class FakeRecord
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Dirty
      
      attr_accessor :attributes
      
      def persisted?
        false
      end
      
      def attribute name
        attributes[name]
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
        cache[record.class][record.id] = from_live(record, cache)
      end
    end
    
    def self.from_live(record, object_cache = nil)
      return nil if record.blank?
      obj = FakeRecord.new
      eigenclass = (class << obj ; self ; end)
      
      obj.instance_variable_set(:@attributes, record.instance_variable_get(:@attributes))
      changed_attributes = Hash.new
      record.previous_changes.each_pair do |attr_name, values|
        changed_attributes[attr_name] = values[0]
      end
      obj.instance_variable_set(:@changed_attributes, changed_attributes)
      
      # associations
      object_cache ||= Hash.new
      object_cache[record.class] ||= Hash.new
      object_cache[record.class][record.id] = obj
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