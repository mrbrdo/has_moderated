require 'spec_helper'

describe HjoinTest do
  it "moderates assoc on create" do
    t = Task.new :title => "Test"
    t.hjoin_tests.build :title => "HJoin"
    t.save
    
    HjoinTest.count.should eq(0)
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    Task.first.hjoin_tests.count.should eq(1)
    Task.first.hjoin_tests.first.title.should eq("HJoin")
  end
  
  it "moderates assoc on update" do
    t = Task.new :title => "Test"
    t.save
    
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    t = Task.first
    t.hjoin_tests.create! :title => "HJoin"
    HjoinTest.count.should eq(0)
    
    Moderation.last.accept
    HjoinTest.count.should eq(1)
    
    Task.first.hjoin_tests.count.should eq(1)
    Task.first.hjoin_tests.first.title.should eq("HJoin")
  end
  
  it "moderates assoc to existing" do
    t = Task.new :title => "Test"
    t.save
    Moderation.last.accept
    
    hjt = HjoinTest.create! :title => "Existing"
    HjoinTest.count.should eq(1)
    
    t = Task.first
    t.hjoin_tests << hjt
    Task.first.hjoin_tests.count.should eq(0)
    
    Moderation.last.accept
        
    Task.first.hjoin_tests.count.should eq(1)
    Task.first.hjoin_tests.first.title.should eq("Existing")
  end
end
