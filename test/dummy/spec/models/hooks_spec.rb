require 'spec_helper'

describe HookTest do
  it "should trigger on creating hook when creating a moderation (create moderation)" do
    HookTest.create!(:title => "TEST")
    val = Moderation.last.attr_value
    val = val[0, 4]
    val.should eq("TEST") # this behavior is defined by the HookTest model
  end
  
  it "should trigger on creating hook when creating a moderation (attribute change moderation)" do
    HookTest.create!(:title => "") # use blank title because of our hook, so moderation is valid
    Moderation.last.accept
    
    HookTest.first.update_attributes :title => "TEST"
    
    val = Moderation.last.attr_value
    val = val[0, 4]
    val.should eq("TEST") # this behavior is defined by the HookTest model
  end
  
  # control test
  it "should not have these testing spaces for other models" do
    Task.create!(:title => "TEST")
    
    val = Moderation.last.attr_value
    val = val[0, 4]
    val.should_not eq("TEST")
  end
end
