module DynamicModelReference
  class << self
    def references
      @references ||= Hash.new
    end

    def get(name)
      references[name.to_sym]
    end

    def create_model(name, model_table_name = nil)
      model_table_name ||= name.to_s.underscore.pluralize
      references[name.to_sym] = Class.new(ActiveRecord::Base) do
        self.table_name = model_table_name
        self
      end
    end

    def clear
      references.clear
    end
  end
end

class DynamicModelBuilder
  def initialize(example)
    @example = example
  end

  def method_missing(name, *args, &block)
    klass_name = name.to_s.camelize
    klass = DynamicModelReference.get(klass_name)
    if klass.nil?
      klass = DynamicModelReference.create_model(klass_name, args[0])
      @example.send(:stub_const, klass_name, klass)
    end
    if block_given?
      klass.class_eval(&block)
    end
    self
  end
end

class RSpec::Core::ExampleGroup
  def dynamic_models &block
    @dynamic_model_builder ||= DynamicModelBuilder.new(self)
  end
end

RSpec.configure do |config|
  config.before(:each) do
    ActiveSupport::Dependencies.clear # clear class cache
    DynamicModelReference.clear
  end
end