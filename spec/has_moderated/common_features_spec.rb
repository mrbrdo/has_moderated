require 'spec_helper'

describe "common features:" do
  it "get_moderation_attributes can be overriden in model" do
    dynamic_models.task {
      has_moderated_create
      self.class_eval do
        def get_moderation_attributes
          { :test => "ok" }
        end
      end
    }
    Task.create! :title => "Task 1"
    data = YAML::load(Moderation.last.data)[:create][:attributes]
    data.should_not be_blank
    data[:test].should_not be_blank
    data[:test].should eq("ok")
    data.keys.count.should eq(1)
  end

  it "knows if it's a create moderation" do
    dynamic_models.task {
      has_moderated_create
    }

    Task.create! :title => "Task 1"

    Moderation.last.create?.should be_true
    Moderation.last.destroy?.should be_false
    Moderation.last.update?.should be_false
  end

  it "knows if it's a destroy moderation" do
    dynamic_models.task {
      has_moderated_destroy
    }

    Task.create! :title => "Task 1"
    Task.last.destroy

    Moderation.last.destroy?.should be_true
    Moderation.last.create?.should be_false
    Moderation.last.update?.should be_false
  end

  it "calls moderation callbacks on destroy" do
    dynamic_models.task {
      has_moderated_create
      def self.moderatable_discard(m, opts)
        raise "moderatable_discard"
      end
    }
    Task.create!
    expect { Moderation.last.destroy }.to raise_error("moderatable_discard")
  end
end