require 'spec_helper'

describe "has_one" do
  context "has_one association:" do
    before do
      dynamic_models.task {
        has_one :renamed_subtask, :class_name => "Subtask", :foreign_key => "task_id"
        has_moderated_association :renamed_subtask
      }.subtask {
        belongs_to :task
      }
    end

    it "creates and associates subtask (= new, task save)" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtask = Subtask.new :title => "Subtask 1"
      task.save

      task = Task.first
      task.renamed_subtask.should be_nil
      Subtask.count.should eq(0)

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

    it "set subtask to nil (delete)" do
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

  context "has_one association (create moderation):" do
    before :each do
      dynamic_models.task {
        has_one :renamed_subtask, :class_name => "Subtask", :foreign_key => "task_id"
        has_moderated_create :with_associations => [:renamed_subtask]
      }.subtask {
        belongs_to :task
      }
    end

    it "associates an existing subtask on create 1" do
      Task.has_moderated_association :renamed_subtask
      Subtask.create! :title => "Subtask 1"
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)

      task = Task.new :title => "Task 1"
      task.renamed_subtask = Subtask.first
      task.save

      Subtask.first.task_id.should be_nil

      Task.count.should eq(0)
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      Subtask.first.task_id.should_not be_nil

      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
    end

    it "associates an existing subtask on create 2" do
      Subtask.create! :title => "Subtask 1"
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)

      task = Task.new :title => "Task 1"
      task.renamed_subtask = Subtask.first
      task.save

      Subtask.first.task_id.should be_nil

      Task.count.should eq(0)
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)
      Subtask.first.task_id.should_not be_nil

      subtask = Task.first.renamed_subtask
      subtask.title.should eq("Subtask 1")
    end
  end
end