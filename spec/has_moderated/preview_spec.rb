require 'spec_helper'

describe "preview:" do
  it "shows a live preview of changed attributes" do
    dynamic_models.task {
      has_moderated :title
    }

    Task.create! :title => "Task 1"
    Task.last.title.should be_blank

    last_task_id = Task.last.id
    Moderation.last.live_preview do |preview|
      preview.title.should eq("Task 1")
      preview.id.should eq(last_task_id)
    end

    Task.last.title.should be_blank
  end

  it "returns a preview for create moderations (issue #13)" do
    dynamic_models.task {
      has_moderated_create
    }

    Task.create! :title => "Task 1"
    Moderation.last.preview.should_not be_nil
    Moderation.last.preview.title.should eq("Task 1")
  end

  it "shows a saved preview of changed attributes" do
    dynamic_models.task {
      has_moderated :title
    }

    task = Task.create! :title => "Task 1"
    Task.last.title.should be_blank

    preview = Moderation.last.preview
    preview.title.should eq("Task 1")
    preview.id.should eq(Task.last.id)
    Task.last.title.should be_blank
  end

  it "supports dirty tracking for the saved preview" do
    dynamic_models.task {
      has_moderated :title
    }

    task = Task.create! :title => "Task 1"
    Task.last.title.should be_blank

    preview = Moderation.last.preview
    preview.title_changed?.should be_true
    preview.title_change.should eq([nil, "Task 1"])
  end

  it "supports updating moderation attributes for the saved preview if :saveable => true" do
    dynamic_models.task {
      has_moderated :title
    }

    task = Task.create! :title => "Task 1"
    Task.last.title.should be_blank

    preview = Moderation.last.preview(:saveable => true)
    preview.title = "Task 2"
    preview.update_moderation

    moderation = Moderation.last
    moderation.parsed_data.should eq({:attributes=>{"title"=>"Task 2"}})
    moderation.accept
    Task.last.title.should eq("Task 2")
  end

  it "doesn't support updating moderation attributes for the saved preview by default" do
    dynamic_models.task {
      has_moderated :title
    }

    task = Task.create! :title => "Task 1"
    Task.last.title.should be_blank

    moderation = Moderation.last
    preview = Moderation.last.preview
    preview.frozen?.should be_true
    expect { preview.title = "Task 2" }.to raise_error
    expect { preview.update_moderation }.to raise_error

    moderation = Moderation.last
    moderation.accept
    Task.last.title.should eq("Task 1")
  end

  it "shows a saved preview of has_many association" do
    dynamic_models.task {
      has_many :renamed_subtasks, :class_name => "Subtask", :foreign_key => "task_id"
      has_moderated_association :renamed_subtasks
    }.subtask {
      belongs_to :task
    }

    task = Task.create! :title => "Task 1"

    task.renamed_subtasks.create! :title => "Subtask 1"
    preview = Moderation.last.preview
    subtask = preview.renamed_subtasks.first
    subtask.title.should eq("Subtask 1")
    subtask.id.should_not be_blank
    subtask.task.should_not be_blank

    Task.last.renamed_subtasks.count.should eq(0)
    Subtask.count.should eq(0)
  end

  it "shows a saved preview of has_many :through association" do
    dynamic_models.task {
      has_many :renamed_connections, :class_name => "TaskConnection", :foreign_key => "m1_id"
      has_many :renamed_subtasks, :class_name => "Subtask", :through => :renamed_connections, :source => :renamed_subtask
      has_moderated_association :renamed_subtasks
      has_moderated_association :renamed_connections
    }.subtask {
      belongs_to :task
      has_many :renamed_connections, :class_name => "TaskConnection", :foreign_key => "m2_id"
      has_many :renamed_tasks, :through => :renamed_connections, :source => :renamed_task
    }.task_connection {
      belongs_to :renamed_task, :class_name => "Task", :foreign_key => "m1_id"
      belongs_to :renamed_subtask, :class_name => "Subtask", :foreign_key => "m2_id"
    }

    task = Task.create! :title => "Task 1"
    conn = TaskConnection.new :title => "Connection 1"
    conn.renamed_subtask = Subtask.new :title => "Subtask 1"
    task.renamed_connections << conn
    task.save

    TaskConnection.count.should eq(0)
    Subtask.count.should eq(0)

    task = Moderation.last.preview

    TaskConnection.count.should eq(0)
    Subtask.count.should eq(0)
    Moderation.count.should eq(1)

    subtask = task.renamed_subtasks.first
    subtask.title.should eq("Subtask 1")
    subtask.renamed_connections.first.should be_present
    conn = task.renamed_connections.first
    conn.title.should eq("Connection 1")
    conn.renamed_subtask.title.should eq("Subtask 1")
    conn.renamed_task.title.should eq("Task 1")

    # everything has to be frozen
    task.frozen?.should be_true
    task.renamed_subtasks.frozen?.should be_true
    task.renamed_connections.frozen?.should be_true
    subtask.frozen?.should be_true
    subtask.renamed_connections.frozen?.should be_true
    conn.frozen?.should be_true
    conn.renamed_task.frozen?.should be_true
    conn.renamed_subtask.frozen?.should be_true
  end

  it "freezes preview correctly" do
    # especially important for Ruby 1.8 which behaves differently
    dynamic_models.task {
      has_many :subtasks
      has_moderated_association :subtasks
    }.subtask {
      belongs_to :task
    }

    t = Task.create!
    t.subtasks.create!

    preview = Moderation.last.preview
    preview.frozen?.should be_true
    preview.instance_variable_get(:@has_moderated_fake_associations).frozen?.should be_true
    preview.subtasks.frozen?.should be_true
  end
end
