require 'spec_helper'

describe HoneAsTest do
  it "moderates assoc on create" do
    t = Task.new :title => "Test"
    t.hone_as_test = HoneAsTest.new :title => "Hone"
    t.save
    
    HoneAsTest.count.should eq(0)
    Task.count.should eq(0)
    
    Moderation.last.accept
    HoneAsTest.count.should eq(1)
    
    Task.first.hone_as_test.title.should eq("Hone")
  end
  
  it "moderates assoc on update" do
    t = Task.new :title => "Test"
    t.save
    
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    t = Task.first
    t.association(:hone_as_test).build :title => "Hone"
    t.save
    HoneAsTest.count.should eq(0)
    
    Moderation.last.accept
    HoneAsTest.count.should eq(1)
    
    Task.first.hone_as_test.title.should eq("Hone")
  end
end
