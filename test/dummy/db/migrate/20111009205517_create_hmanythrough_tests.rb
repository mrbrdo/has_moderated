class CreateHmanythroughTests < ActiveRecord::Migration
  def change
    create_table :hmanythrough_tests do |t|
      t.string :title

      t.timestamps
    end
  end
end
