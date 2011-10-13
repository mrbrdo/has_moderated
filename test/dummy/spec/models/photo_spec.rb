require 'spec_helper'

describe Photo do
  before(:each) do
    FileUtils.rm_rf(TEMPDIR) # remove temp dir
    FileUtils.rm_rf(File.expand_path("../../../public/uploads", __FILE__)) # remove uploads dir
  end
  
  it "should upload photo" do
    photo = Photo.create!(:photo => carrierwave_test_photo)
    
    Photo.count.should eq(0)
    tmpEmpty?.should be_false
    Moderation.last.accept
    tmpEmpty?.should be_true
    
    Photo.count.should eq(1)
    photo = Photo.first
    assert_photo_uploaded(photo.photo)
  end
  
  it "should delete temp files if discarding a photo moderation" do
    photo = Photo.create!(:photo => carrierwave_test_photo)
    
    Photo.count.should eq(0)
    tmpEmpty?.should be_false
    Moderation.last.discard
    tmpEmpty?.should be_true
    
    Photo.count.should eq(0)
  end
  
  it "should put changed photos on existing records to moderation" do
    photo = Photo.create!
    
    Photo.count.should eq(0)
    Moderation.last.accept
    
    p = Photo.first
    p.photo = carrierwave_test_photo
    dirEmpty?(UPLOADDIR).should be_true
    p.save
    dirEmpty?(UPLOADDIR).should be_true
    
    Photo.first.photo.file.should be_nil
    Moderation.count.should eq(1)
    
    tmpEmpty?.should be_false
    Moderation.last.accept
    tmpEmpty?.should be_true
    dirEmpty?(UPLOADDIR).should be_false
    photo = Photo.first
    assert_photo_uploaded(photo.photo)
  end
end
