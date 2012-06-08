# Crazy stuff here! And ugly :-)

def crazy_model_classes
  [:Task, :Subtask, :TaskConnection]
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
    end
  end
  
  def initialize
    @counter = 0
    @current_models = Hash.new
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
      klass = eval("class #{klass_name} < ActiveRecord::Base ; self.table_name = '#{table_name}' ; extend SetupHelpers ; self ; end")
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

Object.send(:remove_const, 'Task') if defined? Task
Object.send(:remove_const, 'Subtask') if defined? Subtask
Object.send(:remove_const, 'TaskConnection') if defined? TaskConnection

crazy_models

crazy_model_classes.each do |name|
  puts name.to_s
  eval("#{name.to_s} = Module.new do ;" \
  "  def self.method_missing(m, *args, &block) ;" \
  "    $crazy_models.access(:'#{name.to_s}', m, *args, &block) ;" \
  "  end ;" \
  "end")
end

# initialize
crazy_models.reset