class CreateTaskPhotos < ActiveRecord::Migration
  def change
    create_table :task_photos do |t|
      t.string :photo
      t.integer :task_id

      t.timestamps
    end
  end
end
