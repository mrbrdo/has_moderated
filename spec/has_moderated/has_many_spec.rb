require 'spec_helper'

describe "has_many association:" do
  before do
    dynamic_models.task {
      has_many :renamed_subtasks, :class_name => "Subtask", :foreign_key => "task_id"
      has_moderated_association :renamed_subtasks
    }.subtask {
      belongs_to :task, :foreign_key => "task_id"
    }
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

  it "moderates deleting association" do
    task = Task.create! :title => "Task 1"
    task.renamed_subtasks.create! :title => "Subtask 1"
    Moderation.last.accept

    Task.last.renamed_subtasks.delete(Task.last.renamed_subtasks.last)
    Task.last.renamed_subtasks.count.should eq(1)

    Moderation.last.accept
    Task.last.renamed_subtasks.count.should eq(0)
  end
end