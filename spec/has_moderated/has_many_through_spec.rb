require 'spec_helper'

describe "has_many :through association:" do
  before do
    dynamic_models.task {
      has_many :renamed_connections, :class_name => "TaskConnection", :foreign_key => "m1_id"
      has_many :renamed_subtasks, :class_name => "Subtask", :through => :renamed_connections, :source => :renamed_subtask
      has_moderated_association :renamed_subtasks
      has_moderated_association :renamed_connections
    }.subtask {
      has_many :renamed_connections, :class_name => "TaskConnection", :foreign_key => "m2_id"
      has_many :renamed_tasks, :through => :renamed_connections, :source => :renamed_task
    }.task_connection {
      belongs_to :renamed_task, :class_name => "Task", :foreign_key => "m1_id"
      belongs_to :renamed_subtask, :class_name => "Subtask", :foreign_key => "m2_id"
    }
  end

  it "associates subtask 1 (update)" do
    task = Task.create! :title => "Task 1"
    Moderation.count.should eq(0)

    conn = TaskConnection.new :title => "Connection 1"
    conn.renamed_subtask = Subtask.new :title => "Subtask 1"
    task.renamed_connections << conn
    task.save

    TaskConnection.count.should eq(0)
    Subtask.count.should eq(0)

    Moderation.last.accept
    Moderation.count.should eq(0)

    subtask = Task.first.renamed_subtasks.first
    subtask.title.should eq("Subtask 1")
    conn = Subtask.first.renamed_connections.first
    conn.title.should eq("Connection 1")
    conn.renamed_subtask.title.should eq("Subtask 1")
    conn.renamed_task.title.should eq("Task 1")
  end

  it "associates subtask 2 (update)" do
    task = Task.create! :title => "Task 1"
    Moderation.count.should eq(0)

    task.renamed_subtasks.build :title => "Subtask 1"
    task.save

    TaskConnection.count.should eq(0)
    Subtask.count.should eq(0)
    Moderation.last.accept
    Moderation.count.should eq(0)
    Subtask.count.should eq(1)

    subtask = Task.first.renamed_subtasks.first
    subtask.title.should eq("Subtask 1")
  end

  it "associates subtask 3 (update)" do
    task = Task.create! :title => "Task 1"
    Moderation.count.should eq(0)

    task.renamed_subtasks.create! :title => "Subtask 1"

    TaskConnection.count.should eq(0)
    Subtask.count.should eq(0)

    Moderation.last.accept
    Moderation.count.should eq(0)
    Subtask.count.should eq(1)

    subtask = Task.first.renamed_subtasks.first
    subtask.title.should eq("Subtask 1")
  end

  it "associates subtask 1 (create)" do
    t = Task.new :title => "Task 1"
    t.renamed_subtasks.build :title => "Subtask 1"
    t.save

    Subtask.count.should eq(0)
    Task.first.title.should eq("Task 1")
    Task.first.renamed_subtasks.count.should eq(0)
    Task.count.should eq(1)

    Moderation.last.accept

    Task.first.renamed_subtasks.count.should eq(1)
    Task.first.renamed_subtasks.first.title.should eq("Subtask 1")
  end
end