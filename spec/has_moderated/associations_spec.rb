require 'spec_helper'

describe "associations" do
  it "can handle nested associations (issue #17 and #18)" do
    dynamic_models.task {
      has_many :subtasks
      has_moderated_create :with_associations => [:subtasks]
    }.subtask {
      belongs_to :task_connection, :foreign_key => "parentable_id"
      belongs_to :task
      has_many :photos, :as => :parentable
      has_moderated :title
    }.photo {
      belongs_to :parentable, :polymorphic => true
    }.task_connection {
      has_many :things, :as => :parentable
    }

    tconn = TaskConnection.create! :title => "TC"
    data = {
      :create => {
        :attributes => { "id" => nil, "title" => "Task" },
        :associations => {
          :subtasks => 
            [
              {"id" => nil, "title" => "Subtask",
                :associations => {
                  :photos => [{"id" => nil, "title" => "Photo"}],
                  :task_connection => [tconn.id]
                }
              }
            ]
        }
      }
    }
    Moderation.create! :moderatable_type => "Task", :data => data.to_yaml
    Moderation.last.accept
    Moderation.count.should eq(0)
    (t = Task.last).title.should eq("Task")
    (s = t.subtasks.last).title.should eq("Subtask")
    s.photos.last.title.should eq("Photo")
    s.task_connection.title.should eq("TC")
  end
end