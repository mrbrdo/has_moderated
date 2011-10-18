require 'spec_helper'

describe HmanyFkTest do
  it "moderates assoc on create" do
    t = Task.new :title => "Test"
    t.lalas.build :title => "HJoin"
    t.save
    
    HmanyFkTest.count.should eq(0)
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    Task.first.lalas.count.should eq(1)
    Task.first.lalas.first.title.should eq("HJoin")
  end
  
  it "moderates assoc on update" do
    t = Task.new :title => "Test"
    t.save
    
    Task.count.should eq(0)
    
    Moderation.last.accept
    
    t = Task.first
    t.lalas.create! :title => "HJoin"
    HmanyFkTest.count.should eq(0)
    
    Moderation.last.accept
    HmanyFkTest.count.should eq(1)
    
    Task.first.lalas.count.should eq(1)
    Task.first.lalas.first.title.should eq("HJoin")
  end
end
