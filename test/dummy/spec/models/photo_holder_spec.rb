require 'spec_helper'

describe PhotoHolder do
  before(:each) do
    FileUtils.rm_rf(TEMPDIR) # remove temp dir
    FileUtils.rm_rf(File.expand_path("../../../public/uploads", __FILE__)) # remove uploads dir
  end
  
  it "should upload photo" do
    photo = PhotoHolder.create!(:photos_attributes => { 0 => {:photo => carrierwave_test_photo}})
    
    Photo.count.should eq(0)
    tmpEmpty?.should be_false
    Moderation.last.accept
    tmpEmpty?.should be_true
    
    Photo.count.should eq(1)
    photo = Photo.first
    assert_photo_uploaded(photo.photo)
  end
end
