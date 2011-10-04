class TaskPhoto < ActiveRecord::Base
  belongs_to :task
  mount_uploader :photo, GenericUploader
  include HasModerated::CarrierWave
end
