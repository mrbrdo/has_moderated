# This is crazy and ugly and a hack! But it works and I don't want to have 100 different model files in models/
# Please do not use this code for your stuff, it's not optimal in any way. I will probably do this more properly when
# I have the time.

def crazy_model_classes
  [:Task, :Subtask, :TaskConnection, :Photo]
end

def crazy_models
  $crazy_models ||= CrazyModels.new
end

class CrazyModels
  module SetupHelpers
    crazy_model_classes.each do |name|
      self.send(:define_method, "#{name.to_s.underscore}_class_name") do
        crazy_models.get_klass(name).to_s
      end
      self.send(:define_method, "#{name.to_s.underscore}_fk") do
        name.to_s.underscore + "_id"
      end
    end
  end
  
  class SetupHelperHolder
    extend SetupHelpers
  end
  
  def initialize
    @counter = 0
    @current_models = Hash.new
  end
  
  def with_helpers &block
    SetupHelperHolder.class_eval &block
  end
  
  crazy_model_classes.each do |name|
    self.send(:define_method, name.to_s.underscore) do |&block|
      @current_models[name].class_eval(&block)
      self
    end
  end
  
  def reset
    @counter += 1
    crazy_model_classes.each do |name|
      klass_name = "#{name}#{@counter}"
      table_name = name.to_s.underscore.pluralize
      klass = Class.new(ActiveRecord::Base) do
        self.table_name = table_name
        extend SetupHelpers
        self
      end
      klass = Object.const_set(klass_name, klass)
      @current_models[name] = klass
    end
    self
  end
  
  def get_klass model_name
    @current_models[model_name]
  end
  
  def access model_name, method, *args, &block
    @current_models[model_name].send(method, *args, &block) if @current_models[model_name]
  end
end

# This part is especially ugly and unncessary, but I'm lazy...
crazy_model_classes.each do |name|
  begin
    Object.instance_eval{ remove_const name }
  rescue ; end
  # proxy module, proxies to current AR model
  m = Module.new do
    def self.method_missing(m, *args, &block)
      $crazy_models.access(name.to_sym, m, *args, &block)
    end
  end
  Object.const_set name.to_s, m
end

# initialize
crazy_models.reset