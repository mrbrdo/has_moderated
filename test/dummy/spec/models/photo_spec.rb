require 'spec_helper'
require 'support/photos'

describe Photo do
  before(:each) do
    FileUtils.rm_rf(TEMPDIR) # remove temp dir
    FileUtils.rm_rf(File.expand_path("../../../public/uploads", __FILE__)) # remove uploads dir
  end
  
  context "create moderated:" do
    before do
      Object.send(:remove_const, 'Photo')
      load 'photo.rb'
      Photo.has_moderated_create
      Photo.send :include, HasModerated::CarrierWave
      Photo.has_moderated_carrierwave_field :avatar
    end
    
    it "should upload photo" do
      photo = Photo.create!(:avatar => carrierwave_test_photo)

      Photo.count.should eq(0)
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      Moderation.last.accept
      tmpEmpty?.should be_true
      uploadEmpty?.should be_false

      Photo.count.should eq(1)
      photo = Photo.first
      assert_photo_uploaded(photo.avatar)
    end
  end

  context "not moderated:" do
    before do
      Object.send(:remove_const, 'Photo')
      load 'photo.rb'
    end
    
    it "should upload photo" do
      photo = Photo.create!(:avatar => carrierwave_test_photo)

      tmpEmpty?.should be_true
      uploadEmpty?.should be_false

      Photo.count.should eq(1)
      photo = Photo.first
      assert_photo_uploaded(photo.avatar)
    end
  end
  
  context "update moderated:" do
    before do
      Object.send(:remove_const, 'Photo')
      load 'photo.rb'
      Photo.send :include, HasModerated::CarrierWave
      Photo.has_moderated_carrierwave_field :avatar
      Photo.has_moderated :avatar
    end

    it "should moderate photo (on create)" do
      photo = Photo.create! :avatar => carrierwave_test_photo
      Photo.count.should eq(1)
      
      Photo.first.avatar.file.should be_nil
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      
      Moderation.last.accept
      tmpEmpty?.should be_true
      uploadEmpty?.should be_false

      Photo.count.should eq(1)
      photo = Photo.first
      assert_photo_uploaded(photo.avatar)
    end
    
    it "should moderate photo (on update)" do
      photo = Photo.create!
      Photo.count.should eq(1)
      
      Photo.first.update_attributes :avatar => carrierwave_test_photo
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      Moderation.last.accept
      tmpEmpty?.should be_true
      uploadEmpty?.should be_false

      Photo.count.should eq(1)
      photo = Photo.first
      assert_photo_uploaded(photo.avatar)
    end
  end
end
