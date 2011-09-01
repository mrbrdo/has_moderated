class CreateModerations < ActiveRecord::Migration
  def self.up
    create_table "moderations" do |t|
      t.integer "moderatable_id",  :null => true
      t.string  "moderatable_type",  :null => false
      t.string  "attr_name",    :limit => 60,  :null => false
      t.text    "attr_value",  :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :moderations
  end
end
