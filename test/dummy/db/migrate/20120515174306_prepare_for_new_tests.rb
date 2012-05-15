class PrepareForNewTests < ActiveRecord::Migration
  def up
    drop_table :task_alls
    drop_table :photos
    drop_table :photo_holders
    drop_table :hook_tests
    drop_table :hone_tests
    drop_table :hone_as_tests
    drop_table :hmanythrough_tests
    drop_table :hmanythrough_joins
    drop_table :hmany_fk_tests
    drop_table :hjoin_tests_tasks
    drop_table :hjoin_tests
    drop_table :habtm_name_tests_tasks
    drop_table :habtm_name_tests

    remove_column :subtasks, :task_all_id
    add_column :subtasks, :parentable_id, :integer
    add_column :subtasks, :parentable_type, :string
    
    create_table "tasks_jointable", :id => false do |t|
      t.integer :m1_id
      t.integer :m2_id
    end
    
    create_table "task_connections" do |t|
      t.string :title
      t.integer :m1_id
      t.integer :m2_id
      t.timestamps
    end
  end

  def down
  end
end
