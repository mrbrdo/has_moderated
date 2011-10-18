require 'spec_helper'

describe HabtmNameTest do
  it "moderates assoc on update" do
    t = Task.new :title => "Test"
    t.save
    
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    t = Task.first
    t.habtms.create! :title => "HJoin"
    HabtmNameTest.count.should eq(0)
    
    Moderation.last.accept
    HabtmNameTest.count.should eq(1)
    
    Task.first.habtms.count.should eq(1)
    Task.first.habtms.first.title.should eq("HJoin")
  end
end
