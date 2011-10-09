class FixJoinTable < ActiveRecord::Migration
  def up
    remove_column :hjoin_tests_tasks, :id
  end

  def down
  end
end
