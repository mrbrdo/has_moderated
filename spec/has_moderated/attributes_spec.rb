require 'spec_helper'

describe "moderates attributes:" do
  it "moderates an attribute" do
    dynamic_models.task {
      has_moderated :title
    }
    Task.create! :title => "Task 1", :desc => "Description"
    Task.first.title.should be_blank
    Task.first.desc.should eq("Description")
    Moderation.last.accept
    Task.first.title.should eq("Task 1")
    Task.first.update_attribute(:title, "Task 2")
    Task.first.title.should eq("Task 1")
    Moderation.last.accept
    Task.first.title.should eq("Task 2")
  end

  it "validates uniqueness properly" do
    dynamic_models.task {
      has_moderated :title
      validates_uniqueness_of :title
    }
    Task.create! :title => "Task 1"
    Task.create! :title => "Task 1"
    Moderation.first.accept
    expect { Task.create! :title => "Task 1" }.to raise_error
    Moderation.first.accept.should be_false
    expect { Moderation.first.accept! }.to raise_error
  end
end