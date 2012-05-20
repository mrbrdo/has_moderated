class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :avatar
      t.string :picture
      t.integer :parentable_id
      t.string :parentable_type
      t.string :title

      t.timestamps
    end
  end
end
