require 'spec_helper'

describe TaskPhoto do
  before(:each) do
    FileUtils.rm_rf(TEMPDIR) # remove temp dir
    FileUtils.rm_rf(File.expand_path("../../../public/uploads", __FILE__)) # remove uploads dir
  end
  
  it "should moderate photos for task on create even if photos themselves are not moderated" do
    t = Task.new :title => "Task 1"
    p = t.task_photos.build
    p.photo = carrierwave_test_photo
    t.save
    Moderation.count.should eq(1)
    Task.count.should eq(0)
    TaskPhoto.count.should eq(0)
    
    Moderation.last.accept
    
    Task.count.should eq(1)
    Task.first.title.should eq("Task 1")
    p = Task.first.task_photos.first
    assert_photo_uploaded(p.photo)
  end
end
