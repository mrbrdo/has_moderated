require 'spec_helper'

describe "destroy moderation:" do
  before do
    dynamic_models.task {
      has_moderated_destroy
    }
  end

  it "moderates destroy" do
    Task.create! :title => "Task 1"
    Task.count.should eq(1)
    Task.first.destroy
    Task.count.should eq(1)
    Moderation.last.accept
    Task.count.should eq(0)
  end

  it "returns nil for #preview" do
    Task.create! :title => "Task 1"
    Task.first.destroy
    Moderation.last.preview.should be_nil
  end
end