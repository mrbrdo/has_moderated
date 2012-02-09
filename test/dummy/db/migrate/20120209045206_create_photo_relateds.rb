class CreatePhotoRelateds < ActiveRecord::Migration
  def change
    create_table :photo_relateds do |t|
      t.integer :photo_id
      t.string :data

      t.timestamps
    end
  end
end
