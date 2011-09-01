class CreateSubtasks < ActiveRecord::Migration
  def change
    create_table :subtasks do |t|
      t.integer :task_id
      t.string :title
      t.string :desc

      t.timestamps
    end
  end
end
