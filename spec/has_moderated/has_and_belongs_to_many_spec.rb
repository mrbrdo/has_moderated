require 'spec_helper'

describe "has_and_belongs_to_many" do
  context "has_and_belongs_to_many association:" do
    before do
      dynamic_models.task {
        has_and_belongs_to_many :renamed_subtasks, :class_name => "Subtask", :join_table => "tasks_jointable", :foreign_key => "m1_id", :association_foreign_key => "m2_id"
        has_moderated_association :renamed_subtasks
      }.subtask {
        has_and_belongs_to_many :renamed_tasks, :class_name => "Task", :join_table => "tasks_jointable", :foreign_key => "m2_id", :association_foreign_key => "m1_id"
      }
    end

    it "creates and associates a new subtask" do
      task = Task.create! :title => "Task 1"
      Moderation.count.should eq(0)
      task.renamed_subtasks.create! :title => "Subtask 1"

      Subtask.count.should eq(0)
      task = Task.first
      task.renamed_subtasks.count.should eq(0)

      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)

      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end

    it "associates an existing subtask" do
      task = Task.create! :title => "Task 1"
      Subtask.create! :title => "Subtask 1"
      Task.first.renamed_subtasks.count.should eq(0)
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)
      task.renamed_subtasks << Subtask.first

      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)

      Task.first.renamed_subtasks.count.should eq(1)
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
  end

  context "has_and_belongs_to_many association (create moderation):" do
    before :each do # important that we do this before EACH
      dynamic_models.task {
        has_moderated_create :with_associations => [:renamed_subtasks]
        has_and_belongs_to_many :renamed_subtasks, :class_name => "Subtask", :join_table => "tasks_jointable", :foreign_key => "m1_id", :association_foreign_key => "m2_id"
      }.subtask {
        has_and_belongs_to_many :renamed_tasks, :class_name => "Task", :join_table => "tasks_jointable", :foreign_key => "m2_id", :association_foreign_key => "m1_id"
      }
    end

    it "associates an existing subtask on create 1" do
      Task.has_moderated_association :renamed_subtasks  # important difference (had different behavior based
                                                        # on presence of this line, need to test with and without)
      Subtask.create! :title => "Subtask 1"
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)

      task = Task.new :title => "Task 1"
      task.renamed_subtasks << Subtask.first
      task.save

      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)

      Task.first.renamed_subtasks.count.should eq(1)
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end

    it "associates an existing subtask on create 2" do
      Subtask.create! :title => "Subtask 1"
      Subtask.count.should eq(1)
      Moderation.count.should eq(0)

      task = Task.new :title => "Task 1"
      task.renamed_subtasks << Subtask.first
      task.save

      Task.count.should eq(0)
      Moderation.count.should eq(1)
      Moderation.last.accept
      Moderation.count.should eq(0)

      Task.last.renamed_subtasks.count.should eq(1)
      subtask = Task.first.renamed_subtasks.first
      subtask.title.should eq("Subtask 1")
    end
  end
end