require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../../support/photos', __FILE__)

def reload_task_photo
  Object.send(:remove_const, 'Task') if defined? Task
  load 'task.rb'
  Object.send(:remove_const, 'Subtask') if defined? Subtask
  load 'subtask.rb'
  Object.send(:remove_const, 'Photo') if defined? Photo
  load 'photo.rb'
end

describe Photo do
  before(:each) do
    FileUtils.rm_rf(TEMPDIR) # remove temp dir
    FileUtils.rm_rf(File.expand_path("../../../public/uploads", __FILE__)) # remove uploads dir
  end
  
  context "create moderated:" do
    before do
      reload_task_photo
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
      reload_task_photo
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
      reload_task_photo
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
  
  context "moderated as association to has_moderated_create:" do
    before do
      reload_task_photo
      Task.has_many :renamed_subtasks, :class_name => "Subtask"
      Task.has_many :photos, :foreign_key => "parentable_id"
      Task.has_moderated_create :with_associations => [:photos, :renamed_subtasks]
      Photo.send :include, HasModerated::CarrierWave
      Photo.has_moderated_carrierwave_field :avatar
      Photo.belongs_to :task, :foreign_key => "parentable_id"
    end
    
    it "should upload photo" do
      task = Task.new :title => "Task 1"
      task.photos.build :avatar => carrierwave_test_photo
      task.save

      Task.count.should eq(0)
      Photo.count.should eq(0)
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      Moderation.last.accept
      tmpEmpty?.should be_true
      uploadEmpty?.should be_false

      Task.first.photos.count.should eq(1)
      photo = Task.first.photos.first
      assert_photo_uploaded(photo.avatar)
    end
    
    it "should not add any photos if none were added" do
      task = Task.new :title => "Task 1"
      task.renamed_subtasks.build :title => "Subtask 1"
      task.save
      
      Moderation.last.parsed_data[:create][:associations][:photos].should be_nil

      Task.count.should eq(0)
      Photo.count.should eq(0)
      Moderation.last.accept

      Task.first.photos.count.should eq(0)
      Photo.count.should eq(0)
    end
  end
end
