require 'spec_helper'

describe "polymorphic associations" do
  #
  # has_moderated_association
  # has_many polymorphic
  #

  context "has_many polymorphic association:" do
    before do
      dynamic_models.task {
        has_many :renamed_subtasks, :class_name => "Subtask", :as => :parentable
        has_moderated_association :renamed_subtasks
      }.subtask {
        belongs_to :parentable, :polymorphic => true
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
      subtask.parentable.should eq(Task.first)
    end
  end

  #
  # has_moderated_association
  # has_one polymorphic
  #

  context "has_one polymorphic association:" do
    before do
      dynamic_models.task {
        has_one :renamed_subtask, :class_name => "Subtask", :as => :parentable
        has_moderated_association :renamed_subtask
      }.subtask {
        belongs_to :parentable, :polymorphic => true
      }
    end

    it "creates and associates subtask (create)" do
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
      subtask.parentable.should eq(Task.first)
    end
  end
end