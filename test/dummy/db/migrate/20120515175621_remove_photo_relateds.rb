class RemovePhotoRelateds < ActiveRecord::Migration
  def up
    drop_table :photo_relateds
  end

  def down
  end
end
