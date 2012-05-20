class Photo < ActiveRecord::Base
  mount_uploader :avatar, GenericUploader
  mount_uploader :picture, GenericUploader
end
