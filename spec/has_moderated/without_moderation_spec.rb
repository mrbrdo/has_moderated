require 'spec_helper'

describe "without_moderation:" do
  before do
    dynamic_models.task {
      has_moderated :title
    }
  end

  it "can bypass moderation for specific model" do
    Task.create!
    Moderation.count.should eq(0)
    t = Task.first
    t.title = "Task 2"
    t.without_moderation do
      t.save
    end
    Moderation.count.should eq(0)
    Task.first.title.should eq("Task 2")
  end

  it "can bypass moderation for all models" do
    Task.create!
    Moderation.count.should eq(0)
    t = Task.first
    t.title = "Task 2"
    Moderation.without_moderation do
      t.save
    end
    Moderation.count.should eq(0)
    Task.first.title.should eq("Task 2")
    Moderation.moderation_disabled.should be_false
    t.title = "Task 3"
    t.save
    Moderation.count.should eq(1)
    Task.first.title.should eq("Task 2")
  end
end