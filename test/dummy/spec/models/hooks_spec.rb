require 'spec_helper'

describe HookTest do
  it "should trigger on creating hook when creating a moderation (create moderation)" do
    HookTest.create!(:title => "hello")
    val = Moderation.last.attr_value
    val = val[0, 2]
    val.should eq("  ") # this behavior is defined by the HookTest model
  end
  
  it "should trigger on creating hook when creating a moderation (attribute change moderation)" do
    HookTest.create!(:title => "hello")
    Moderation.last.accept
    
    HookTest.first.update_attributes :title => "Jojo"
    
    val = Moderation.last.attr_value
    val = val[0, 2]
    val.should eq("  ") # this behavior is defined by the HookTest model
    # Note: these spaces don't affect the actual value because it is in YAML format
    
    # just to be safe
    Moderation.last.accept
    HookTest.first.title.should eq("Jojo")
  end
  
  # control test
  it "should not have these testing spaces for other models" do
    Task.create!(:title => "Hello")
    
    val = Moderation.last.attr_value
    val = val[0, 2]
    val.should_not eq("  ")
  end
end
