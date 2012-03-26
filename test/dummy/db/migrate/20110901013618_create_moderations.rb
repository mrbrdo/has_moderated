class CreateModerations < ActiveRecord::Migration
  def self.up
    if table_exists? :moderations # for upgrading
      Moderation.all.each { |m| m.accept }
      drop_table :moderations
    end

    create_table :moderations do |t|
      t.integer :moderatable_id,   :null => true
      t.string  :moderatable_type, :null => false
      t.string  :attr_name,        :null => false, :limit => 60
      t.text    :attr_value,       :null => false
      t.timestamps
    end

    add_index :moderations, :moderatable_type
    add_index :moderations, [:moderatable_type, :moderatable_id]
  end

  def self.down
    drop_table :moderations
  end
end
