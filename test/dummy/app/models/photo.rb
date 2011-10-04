class Photo < ActiveRecord::Base
  belongs_to :photo_holder
  mount_uploader :photo, GenericUploader
  has_moderated_create
  has_moderated :photo
  include HasModerated::CarrierWave
end
