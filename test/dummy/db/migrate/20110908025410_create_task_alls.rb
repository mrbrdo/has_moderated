class CreateTaskAlls < ActiveRecord::Migration
  def change
    create_table :task_alls do |t|
      t.string :title
      t.string :value

      t.timestamps
    end
  end
end
