require 'spec_helper'

describe Task do
  it "doesn't store new tasks in the database, but in moderations" do
    Task.has_many :subtasks
    Task.has_moderated_association :subtasks
    
    task = Task.create! :title => "Bye Bye"
    task.subtasks.create! :title => "Hello"
  end
end
