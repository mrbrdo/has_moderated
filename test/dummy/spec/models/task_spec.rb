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

  it "remembers associations to existing records on create" do
    subtask = Subtask.create! :title => "Bye Bye"
    Subtask.count.should eq(1)

    t = Task.new :title => "Hollywood Hills"
    t.subtasks << subtask
    t.save

    Task.count.should eq(0)
    Subtask.first.task.should be_nil

    Moderation.last.accept
    Subtask.first.task.should_not be_nil
    t = Task.first
    t.subtasks.count.should eq(1)
    t.subtasks.first.title.should eq("Bye Bye")
  end

  it "accepts :all for has_moderated_create's :with_associations option" do
    t = TaskAll.new :title => "Bye Bye"
    t.subtasks.build :title => "Hollywood Hills"
    t.save

    TaskAll.count.should eq(0)
    Subtask.count.should eq(0)

    Moderation.last.accept
    
    TaskAll.count.should eq(1)
    Subtask.count.should eq(1)
    TaskAll.first.title.should eq("Bye Bye")
    TaskAll.first.subtasks.first.title.should eq("Hollywood Hills")
  end

  it "ignores associations to existing records that were deleted" do
    subtask = Subtask.create! :title => "Bye Bye"
    Subtask.count.should eq(1)

    t = Task.new :title => "Hollywood Hills"
    t.subtasks << subtask
    t.save

    Task.count.should eq(0)
    Subtask.delete_all
    Subtask.count.should eq(0)
    
    Moderation.last.accept
    Task.first.subtasks.count.should eq(0)
    Subtask.count.should eq(0)
  end

  it "moderates destroy" do
    Task.create! :title => "Bye Bye"
    Moderation.last.accept
    
    Task.count.should eq(1)

    Task.first.destroy
    Task.count.should eq(1)

    Moderation.last.accept
    Task.count.should eq(0)
  end

  it "moderates new associations on existing records (add_associations_moderated)" do
    t = Task.create! :title => "Bye Bye"
    Moderation.last.accept

    t = Task.first
    t.add_associations_moderated(:subtasks => [Subtask.new(:task_id => t.id, :title => "Hollywood Hills")])
    t.subtasks.count.should eq(0)
    t.save
    t.subtasks.count.should eq(0)
    Subtask.count.should eq(0)

    Moderation.last.accept
    t.subtasks.count.should eq(1)
    Subtask.count.should eq(1)
    Task.first.subtasks.first.title.should eq("Hollywood Hills")
  end

  it "moderates new associations to existing records on existing records (add_associations_moderated)" do
    sub = Subtask.create! :title => "Hollywood Hills"
    t = Task.create! :title => "Bye Bye"
    Moderation.last.accept

    t = Task.first
    t.add_associations_moderated(:subtasks => [sub])
    t.subtasks.count.should eq(0)
    Subtask.count.should eq(1)
    t.save
    t.subtasks.count.should eq(0)

    Moderation.last.accept
    t.subtasks.count.should eq(1)
    Subtask.count.should eq(1)
    Task.first.subtasks.first.title.should eq("Hollywood Hills")
  end
  
  it "moderates new associations with build" do
    Task.create! :title => "Bye Bye"
    Moderation.last.accept
    
    t = Task.last
    t.subtasks.build :title => "Jo jo"
    # TODO
    # Moderation.count.should eq(0)
    t.save
    Moderation.count.should eq(1)
    
    Task.last.subtasks.count.should eq(0)
    Moderation.last.accept
    Task.last.subtasks.first.title.should eq("Jo jo")
  end
  
  it "moderates associations to existing records with <<" do
    Task.create! :title => "Bye Bye"
    Moderation.last.accept
    Subtask.create! :title => "Jo jo"
    
    Moderation.count.should eq(0)
    
    t = Task.first
    t.subtasks << Subtask.first
    
    Task.first.subtasks.count.should eq(0)
    Moderation.last.accept
    
    st = Task.first.subtasks.first
    st.title.should eq("Jo jo")
    st.id.should eq(Subtask.first.id)
  end
  
  it "should moderate removing an association" do
    t = Task.new :title => "Test"
    t.subtasks.build :title => "HJoin"
    t.subtasks.build :title => "HJoin2"
    t.save
    Moderation.last.accept
    
    Task.count.should eq(1)
    t = Task.first
    t.subtasks.count.should eq(2)
    
    first_subtask = t.subtasks.first
    t.subtasks.delete(first_subtask)
    
    t = Task.first
    t.subtasks.count.should eq(2)
    Moderation.count.should eq(1)
    
    Moderation.last.accept
    t = Task.first
    t.subtasks.count.should eq(1)
    t.subtasks.first.title.should_not eq(first_subtask.title)
  end
end
