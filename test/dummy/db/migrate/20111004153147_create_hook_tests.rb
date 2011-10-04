class CreateHookTests < ActiveRecord::Migration
  def change
    create_table :hook_tests do |t|
      t.string :title
      t.string :foo

      t.timestamps
    end
  end
end
