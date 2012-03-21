require 'spec_helper'

describe Task do
  
  #
  # has_moderated_association
  # has_many
  #
  
  context "has_many association:" do
    before do
      Object.send(:remove_const, 'Task')
      load 'task.rb'
      # TODO: set very obscure options
      Task.has_many :renamed_subtasks, :class_name => "Subtask"
      Task.has_moderated_association :renamed_subtasks
    end
    
    it "creates and associates subtask (create)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.create! :title => "Subtask 1"
    
      task = Task.first
      task.renamed_subtasks.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "creates and associates subtask (build, save task)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.build :title => "Subtask 1"
      task.save
    
      task = Task.first
      task.renamed_subtasks.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "creates and associates subtask (build, save subtask)", :broken => true do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      subtask = task.renamed_subtasks.build :title => "Subtask 1"
      subtask.save
    
      task = Task.first
      task.renamed_subtasks.count.should eq(0)
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates (<<) existing subtask" do
      task = Task.create! :title => "Task 1"
      Subtask.create! :title => "Subtask 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks << Subtask.first

      task = Task.first
      task.renamed_subtasks.count.should eq(0)

      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)

      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
    
    it "associates (push) existing subtask" do
      task = Task.create! :title => "Task 1"
      Subtask.create! :title => "Subtask 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.push Subtask.first

      task = Task.first
      task.renamed_subtasks.count.should eq(0)

      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)

      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
  end
  
  #
  # has_moderated_association
  # has_one
  #
  
  context "has_one association:" do
    before do
      Object.send(:remove_const, 'Task')
      load 'task.rb'
      Task.has_one :renamed_subtask, :class_name => "Subtask"
      Task.has_moderated_association :renamed_subtask
    end
    
    it "creates and associates subtask (= new, task save)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtask = Subtask.new :title => "Subtask 1"
      task.save
    
      task = Task.first
      task.renamed_subtask.should be_nil
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
    end
    
    it "creates and associates subtask (= create, task save)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtask = Subtask.create! :title => "Subtask 1"
      task.save
    
      task = Task.first
      task.renamed_subtask.should be_nil
    
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      
      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
    end
    
    it "set subtask to nil", :broken => true do
      task = Task.create! :title => "Task 1"
      task.renamed_subtask = Subtask.new :title => "Subtask 1"
      task.save
      Moderation.last.accept
      
      Moderation.count.should eq(0)
      Task.first.renamed_subtask.should_not be_nil
      
      Task.first.renamed_subtask = nil
      Task.first.renamed_subtask.should_not be_nil
      
      Moderation.last.accept
      Task.first.renamed_subtask.should be_nil
    end
  end
  
  it "get_moderation_attributes can be overriden in model"
end
