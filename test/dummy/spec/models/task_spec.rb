require 'spec_helper'

describe Task do
  it "doesn't store new tasks in the database, but in moderations" do
    Task.create! :title => "Bye Bye"
    Task.count.should eq(0)
    Moderation.count.should eq(1)
  end
  
  it "restores a new record properly from an accepted moderation and the moderation is removed" do
    Task.create! :title => "Bye Bye"
    Moderation.last.accept

    Moderation.count.should eq(0)
    Task.count.should eq(1)

    t = Task.last
    t.title.should eq("Bye Bye")
  end

  it "doesn't store updated moderated attributes in the database, but in moderations" do
    Task.create! :title => "Bye Bye"
    Moderation.last.accept

    # test different ways (will generate more than one moderation)
    # 1
    Task.last.update_attributes(:title => "Hollywood Hills")
    # 2
    t = Task.last
    t.title = "Hollywood Hills"
    t.save
    # 3
    Task.last.update_attribute(:title, "Hollywood Hills")
    # 4
    t = Task.last
    t.attributes = { :title => "Hollywood Hills" }
    t.save
    
    Moderation.count.should eq(4)

    Task.last.title.should eq("Bye Bye")
    Moderation.last.accept
    Task.last.title.should eq("Hollywood Hills")
    Task.count.should eq(1)
  end

  it "properly discards a create moderation" do
    Task.create! :title => "Bye Bye"
    Moderation.last.discard

    Task.count.should eq(0)
    Moderation.count.should eq(0)
  end

  it "properly discards an update moderation" do
    Task.create! :title => "Bye Bye"
    Moderation.last.accept

    Task.last.update_attributes(:title => "Hollywood Hills")

    Moderation.last.discard

    Task.count.should eq(1)
    Task.last.title.should eq("Bye Bye")
    Moderation.count.should eq(0)
  end

  it "properly stores an associated subtask in moderations" do
    t = Task.new :title => "Bye Bye"
    t.subtasks.build :title => "Hollywood Hills"
    t.save

    Task.count.should eq(0)
    Subtask.count.should eq(0)

    Moderation.last.accept
    Moderation.count.should eq(0)

    t = Task.last
    t.title.should eq("Bye Bye")
    t.subtasks.count.should eq(1)
    t.subtasks.first.title.should eq("Hollywood Hills")
  end

  it "bypasses attr_accessible when applying a create moderation" do
    # desc is not attr_accessible, can't use mass assign to create
    t = Task.new :title => "Bye Bye"
    t.desc = "Hollywood Hills"
    t.save
    
    Moderation.count.should eq(1)
    
    Moderation.last.accept

    Moderation.count.should eq(0)
    Task.last.title.should eq("Bye Bye") # just so we know it's created properly
    Task.last.desc.should eq("Hollywood Hills")
  end

  it "bypasses attr_accessible when applying an update moderation" do
    Task.create! :title => "Bye Bye"
    Moderation.last.accept

    # desc is not attr_accessible
    t = Task.last
    t.desc = "Hollywood Hills"
    t.save

    Moderation.count.should eq(1)

    Task.last.desc.should be_nil
    Moderation.last.accept
    Task.last.desc.should eq("Hollywood Hills")
  end
end
