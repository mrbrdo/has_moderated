class CreateModerations < ActiveRecord::Migration
  def self.up
    if table_exists? :moderations # for upgrading
      if Moderation.count > 0
        raise "Moderations table must be empty before upgrading has_moderated!"
      end
      drop_table :moderations
    end
    create_table "moderations" do |t|
      t.integer "moderatable_id",  :null => true
      t.string  "moderatable_type",  :null => true
      t.text    "data",  :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :moderations
  end
end
