require 'spec_helper'

describe "hooks:" do
  before do
    dynamic_models.task {
      has_moderated :title
      moderation_creating do |moderation|
        moderation.data = "Test!"
      end
    }
  end

  it "handles a creating hook properly" do
    Task.create! :title => "Task 1"
    Moderation.count.should eq(1)
    Moderation.last.data.should eq("Test!")
  end
end