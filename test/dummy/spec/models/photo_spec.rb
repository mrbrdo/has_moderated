require 'spec_helper'
require 'fileutils'

def dirEmpty? dirname
  return true unless File.directory?(dirname)
  Dir.entries(dirname).size == 2
end

tempdir = File.expand_path("../../../public/uploads/tmp", __FILE__)
uploaddir = "/Users/apple/rails/has_moderated/test/dummy/public/uploads/photo/photo/1"
SAMPLE_PHOTO_URL = "http://www.arnes.si/typo3conf/ext/ag_arnes_eff_template/templates/template-index/images/logo_arnes.gif"

describe Photo do
  before(:each) do
    FileUtils.rm_rf(tempdir) # remove temp dir
    FileUtils.rm_rf(File.expand_path("../../../public/uploads", __FILE__)) # remove uploads dir
  end
  
  it "should upload photo" do
    photo = Photo.create!(:remote_photo_url => SAMPLE_PHOTO_URL)
    
    Photo.count.should eq(0)
    dirEmpty?(tempdir).should be_false
    Moderation.last.accept
    dirEmpty?(tempdir).should be_true
    
    Photo.count.should eq(1)
    photo = Photo.first
    photo.photo.should_not be_nil
    photo.photo.file.should_not be_nil
    photo.photo.file.file.should_not be_nil
  end
  
  it "should delete temp files if discarding a photo moderation" do
    photo = Photo.create!(:remote_photo_url => SAMPLE_PHOTO_URL)
    
    Photo.count.should eq(0)
    dirEmpty?(tempdir).should be_false
    Moderation.last.discard
    dirEmpty?(tempdir).should be_true
    
    Photo.count.should eq(0)
  end
  
  it "should put changed photos on existing records to moderation" do
    photo = Photo.create!
    
    Photo.count.should eq(0)
    Moderation.last.accept
    
    p = Photo.first
    p.remote_photo_url = SAMPLE_PHOTO_URL
    dirEmpty?(uploaddir).should be_true
    p.save
    dirEmpty?(uploaddir).should be_true
    
    Photo.first.photo.file.should be_nil
    Moderation.count.should eq(1)
    
    dirEmpty?(tempdir).should be_false
    Moderation.last.accept
    dirEmpty?(tempdir).should be_true
    dirEmpty?(uploaddir).should be_false
    Photo.first.photo.file.should_not be_nil
    File.exist?(Photo.first.photo.file.file).should be_true
    assert(Photo.first.photo.file.file =~ /photo\/1\/logo_arnes.gif\Z/)
  end
end
