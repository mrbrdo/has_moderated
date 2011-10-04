require 'spec_helper'
require 'fileutils'

def dirEmpty? dirname
  return true unless File.directory?(dirname)
  Dir.entries(dirname).size == 2
end

tempdir = File.expand_path("../../../public/uploads/tmp", __FILE__)
uploaddir = "/Users/apple/rails/has_moderated/test/dummy/public/uploads/photo/photo/1"
SAMPLE_PHOTO_URL = "http://www.arnes.si/typo3conf/ext/ag_arnes_eff_template/templates/template-index/images/logo_arnes.gif"

describe PhotoHolder do
  it "should upload photo" do
    photo = PhotoHolder.create!(:photos_attributes => { 0 => {:remote_photo_url => SAMPLE_PHOTO_URL}})
    
    Photo.count.should eq(0)
    dirEmpty?(tempdir).should be_false
    Moderation.last.accept
    dirEmpty?(tempdir).should be_true
    
    Photo.count.should eq(1)
    photo = Photo.first
    photo.photo.should_not be_nil
    photo.photo.file.should_not be_nil
    photo.photo.file.file.should_not be_nil
    assert(Photo.first.photo.file.file =~ /photo\/1\/logo_arnes.gif\Z/)
  end
end
