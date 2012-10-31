require File.expand_path('../../spec_helper', __FILE__)

def reload_models
  crazy_models.reset
  crazy_models.with_helpers &block if block_given?
  crazy_models
end

describe Photo do
  before(:each) do
    FileUtils.rm_rf(TEMPDIR) # remove temp dir
    FileUtils.rm_rf(File.expand_path("../../../public/uploads", __FILE__)) # remove uploads dir
  end

  context "create moderated:" do
    before do
      reload_models.photo {
        mount_uploader :avatar, GenericUploader
        has_moderated_create
        send :include, HasModerated::CarrierWave
        has_moderated_carrierwave_field :avatar
      }
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

    it "should not move temp file when doing preview" do
      photo = Photo.create!(:avatar => carrierwave_test_photo)

      Photo.count.should eq(0)
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      Moderation.last.preview
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
    end
  end

  context "not moderated:" do
    before do
      reload_models.photo {
        mount_uploader :avatar, GenericUploader
      }
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
      reload_models.photo {
        mount_uploader :avatar, GenericUploader
        send :include, HasModerated::CarrierWave
        has_moderated_carrierwave_field :avatar
        has_moderated :avatar
      }
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

    it "should delete temporary files if moderation is discarded" do
      photo = Photo.create! :avatar => carrierwave_test_photo
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      Moderation.last.discard
      tmpEmpty?.should be_true
      uploadEmpty?.should be_true
    end

    it "should not move temp file when doing preview" do
      photo = Photo.create! :avatar => carrierwave_test_photo
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      Moderation.last.preview
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
    end
  end

  context "moderated as association to has_moderated_create:" do
    before do
      reload_models.task {
        has_many :renamed_subtasks, :class_name => subtask_class_name, :foreign_key => task_fk
        has_many :photos, :class_name => photo_class_name, :foreign_key => "parentable_id"
        has_moderated_create :with_associations => [:photos, :renamed_subtasks]
      }.subtask {
        belongs_to :task, :class_name => task_class_name
      }.photo {
        mount_uploader :avatar, GenericUploader
        send :include, HasModerated::CarrierWave
        has_moderated_carrierwave_field :avatar
        belongs_to :task, :class_name => task_class_name, :foreign_key => "parentable_id"
      }

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

    it "should not move temp file when doing preview" do
      task = Task.new :title => "Task 1"
      task.photos.build :avatar => carrierwave_test_photo
      task.save

      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      Moderation.last.preview
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
    end
  end

  context "moderation preview" do
    it "should show the temporary file as the photo" do
      reload_models.photo {
        mount_uploader :avatar, GenericUploader
        send :include, HasModerated::CarrierWave
        has_moderated_carrierwave_field :avatar
        has_moderated :avatar
      }

      photo_file = carrierwave_test_photo
      photo = Photo.create! :avatar => photo_file
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      preview = Moderation.last.preview
      preview.avatar.url.should match(/\A\/uploads\/tmp\/.+\/test.jpg\z/)
      preview.avatar.current_path.should eq(Moderation.last.parsed_data[:attributes]["avatar_tmp_file"])
      preview.avatar_url.should eq(preview.avatar.url)
      preview.avatar.file.class.should eq(::CarrierWave::HasModeratedTempFile)

      Photo.last.avatar.current_path.should be_blank
      Photo.last.avatar_url.should be_blank
    end

    it "should show the temporary file as the photo (create moderation)" do
      reload_models.photo {
        mount_uploader :avatar, GenericUploader
        send :include, HasModerated::CarrierWave
        has_moderated_create
        has_moderated_carrierwave_field :avatar
      }

      photo_file = carrierwave_test_photo
      photo = Photo.create! :avatar => photo_file
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      preview = Moderation.last.preview
      preview.avatar.url.should match(/\A\/uploads\/tmp\/.+\/test.jpg\z/)
      preview.avatar.current_path.should eq(Moderation.last.parsed_data[:create][:attributes]["avatar_tmp_file"])
      preview.avatar_url.should eq(preview.avatar.url)
      preview.avatar.file.class.should eq(::CarrierWave::HasModeratedTempFile)
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
    end

    it "should show the temporary file as the photo (create assoc moderation)" do
      reload_models.task {
        has_many :photos, :class_name => photo_class_name, :foreign_key => "parentable_id"
        has_moderated_create :with_associations => [:photos]
      }.photo {
        mount_uploader :avatar, GenericUploader
        send :include, HasModerated::CarrierWave
        has_moderated_carrierwave_field :avatar
        belongs_to :task, :class_name => task_class_name, :foreign_key => "parentable_id"
      }

      photo_file = carrierwave_test_photo
      task = Task.new
      photo = task.photos.build :avatar => photo_file
      task.save
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      preview = Moderation.last.preview.photos.first
      preview.avatar.url.should match(/\A\/uploads\/tmp\/.+\/test.jpg\z/)
      preview.avatar.current_path.should eq(Moderation.last.parsed_data[:create][:associations][:photos].first["avatar_tmp_file"])
      preview.avatar_url.should eq(preview.avatar.url)
      preview.avatar.file.class.should eq(::CarrierWave::HasModeratedTempFile)
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
    end

    it "should show the temporary file as the photo (assoc moderation)" do
      reload_models.task {
        has_many :photos, :class_name => photo_class_name, :foreign_key => "parentable_id"
        has_moderated_association :photos
      }.photo {
        mount_uploader :avatar, GenericUploader
        send :include, HasModerated::CarrierWave
        has_moderated_carrierwave_field :avatar
        belongs_to :task, :class_name => task_class_name, :foreign_key => "parentable_id"
      }

      photo_file = carrierwave_test_photo
      task = Task.new
      photo = task.photos.build :avatar => photo_file
      task.save
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
      preview = Moderation.last.preview.photos.first
      preview.avatar.url.should match(/\A\/uploads\/tmp\/.+\/test.jpg\z/)
      preview.avatar.current_path.should eq(Moderation.last.parsed_data[:associations][:photos].first["avatar_tmp_file"])
      preview.avatar_url.should eq(preview.avatar.url)
      preview.avatar.file.class.should eq(::CarrierWave::HasModeratedTempFile)
      tmpEmpty?.should be_false
      uploadEmpty?.should be_true
    end
  end
end
