class Photo < ActiveRecord::Base
  mount_uploader :photo, GenericUploader
  has_moderated_create
  has_moderated :photo
  include HasModerated::CarrierWave
end
