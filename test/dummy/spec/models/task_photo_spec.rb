require 'spec_helper'

tempdir = File.expand_path("../../../public/uploads/tmp", __FILE__)
uploaddir = "/Users/apple/rails/has_moderated/test/dummy/public/uploads/photo/photo/1"
SAMPLE_PHOTO_URL = "http://www.arnes.si/typo3conf/ext/ag_arnes_eff_template/templates/template-index/images/logo_arnes.gif"

describe TaskPhoto do
  before(:each) do
    FileUtils.rm_rf(tempdir) # remove temp dir
    FileUtils.rm_rf(File.expand_path("../../../public/uploads", __FILE__)) # remove uploads dir
  end
  
  it "should moderate photos for task on create even if photos themselves are not moderated" do
    t = Task.new :title => "Task 1"
    p = t.task_photos.build
    p.remote_photo_url = SAMPLE_PHOTO_URL
    t.save
    Moderation.count.should eq(1)
    Task.count.should eq(0)
    TaskPhoto.count.should eq(0)
    
    Moderation.last.accept
    
    Task.count.should eq(1)
    Task.first.title.should eq("Task 1")
    p = Task.first.task_photos.first
    p.should_not be_nil
    p.photo.should_not be_nil
    p.photo.file.should_not be_nil
  end
end
