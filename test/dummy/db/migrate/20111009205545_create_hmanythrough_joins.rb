class CreateHmanythroughJoins < ActiveRecord::Migration
  def change
    create_table :hmanythrough_joins do |t|
      t.integer :hmanythrough_test_id
      t.integer :task_id
      t.string :exdata

      t.timestamps
    end
  end
end
