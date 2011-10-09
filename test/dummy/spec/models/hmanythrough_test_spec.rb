require 'spec_helper'

describe HmanythroughTest do
  it "moderates assoc on create" do
    t = Task.new :title => "Test"
    t.hmanythrough_test.build :title => "HJoin"
    t.save
    
    HmanythroughTest.count.should eq(0)
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    Task.first.hmanythrough_test.count.should eq(1)
    Task.first.hmanythrough_test.first.title.should eq("HJoin")
  end
  
  it "moderates assoc on update" do
    t = Task.new :title => "Test"
    t.save
    
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    t = Task.first
    t.hmanythrough_test.create! :title => "HJoin"
    HmanythroughTest.count.should eq(0)
    
    Moderation.last.accept
    HmanythroughTest.count.should eq(1)
    
    Task.first.hmanythrough_test.count.should eq(1)
    Task.first.hmanythrough_test.first.title.should eq("HJoin")
  end
  
  it "moderates assoc on update (through model)" do
    t = Task.new :title => "Test"
    t.save
    
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    t = Task.first
    j = HmanythroughJoin.new :exdata => "Data"
    j.hmanythrough_test = HmanythroughTest.new :title => "Hello"
    t.hmanythrough_join << j
    t.save
    HmanythroughTest.count.should eq(0)
    
    Moderation.last.accept
    HmanythroughTest.count.should eq(1)
    
    Task.first.hmanythrough_test.count.should eq(1)
    Task.first.hmanythrough_test.first.title.should eq("Hello")
    Task.first.hmanythrough_test.first.hmanythrough_join.first.exdata.should eq("Data")
  end
  
  it "moderates assoc on update (through model) 2" do
    pending("need to figure this out, hook will trigger when calling build already")
    t = Task.new :title => "Test"
    t.save
    
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    t = Task.first
    j = t.hmanythrough_join.build :exdata => "Data"
    j.hmanythrough_test = HmanythroughTest.new :title => "Hello"
    t.save
    HmanythroughTest.count.should eq(0)
    
    raise Moderation.last.to_yaml
    Moderation.last.accept
    HmanythroughTest.count.should eq(1)
    
    Task.first.hmanythrough_test.count.should eq(1)
    Task.first.hmanythrough_test.first.title.should eq("Hello")
  end
  
  it "moderates assoc extra data on create" do
    t = Task.new :title => "Test"
    j = t.hmanythrough_join.build :exdata => "Data"
    j.hmanythrough_test = HmanythroughTest.new :title => "Hello"
    t.save
    
    HmanythroughTest.count.should eq(0)
    Task.count.should eq(0)
    
    Moderation.last.accept
    HmanythroughTest.count.should eq(1)
    
    Task.first.hmanythrough_test.count.should eq(1)
    Task.first.hmanythrough_test.first.title.should eq("Hello")
    Task.first.hmanythrough_test.first.hmanythrough_join.first.exdata.should eq("Data")
  end
end
