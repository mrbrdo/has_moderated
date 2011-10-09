require 'spec_helper'

describe HoneTest do
  it "moderates assoc on create" do
    t = Task.new :title => "Test"
    t.hone_test = HoneTest.new :title => "Hone"
    t.save
    
    HoneTest.count.should eq(0)
    Task.count.should eq(0)
    
    Moderation.last.accept
    HoneTest.count.should eq(1)
    
    Task.first.hone_test.title.should eq("Hone")
  end
  
  it "moderates assoc on update" do
    t = Task.new :title => "Test"
    t.save
    
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    t = Task.first
    t.association(:hone_test).build :title => "Hone"
    t.save
    HoneTest.count.should eq(0)
    
    Moderation.last.accept
    HoneTest.count.should eq(1)
    
    Task.first.hone_test.title.should eq("Hone")
  end
end
