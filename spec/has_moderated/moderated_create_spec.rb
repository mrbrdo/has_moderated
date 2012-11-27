require 'spec_helper'

describe "create moderation with association:" do
  before do
    dynamic_models.task {
      has_many :renamed_subtasks, :class_name => "Subtask", :foreign_key => "task_id"
      has_moderated_create :with_associations => [:renamed_subtasks]
    }.subtask {
      belongs_to :task
    }
  end

  it "moderates create" do
    task = Task.create! :title => "Task 1"
    Moderation.count.should eq(1)
    Task.count.should eq(0)

    Moderation.last.accept
    Task.count.should eq(1)
    Task.first.title.should eq("Task 1")
  end

  # TODO: test all associations on create
  it "moderates assoc on create" do
    task = Task.new :title => "Task 1"
    task.renamed_subtasks.build :title => "Subtask 1"
    task.save
    Subtask.count.should eq(0)
    Moderation.last.accept

    Task.last.renamed_subtasks.count.should eq(1)
    Task.last.renamed_subtasks.first.title.should eq("Subtask 1")
  end

  it "doesn't create anything if nothing was created" do
    task = Task.create! :title => "Task 1"
    Moderation.last.accept

    Task.first.renamed_subtasks.count.should eq(0)
  end
end