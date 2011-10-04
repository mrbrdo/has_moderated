class CreatePhotoHolders < ActiveRecord::Migration
  def change
    create_table :photo_holders do |t|
      t.string :title

      t.timestamps
    end
    add_column :photos, :photo_holder_id, :integer
  end
end
