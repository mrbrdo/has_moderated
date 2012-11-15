ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => File.expand_path('../../test.sqlite3', __FILE__)
)

class CreateSchema < ActiveRecord::Migration
  def change
    create_table "moderations" do |t|
      t.integer  "moderatable_id"
      t.string   "moderatable_type"
      t.text     "data",             :null => false

      t.timestamps
    end

    create_table "subtasks" do |t|
      t.integer  "task_id"
      t.string   "title"
      t.string   "desc"
      t.integer  "parentable_id"
      t.string   "parentable_type"

      t.timestamps
    end

    create_table "task_connections" do |t|
      t.string   "title"
      t.integer  "m1_id"
      t.integer  "m2_id"

      t.timestamps
    end

    create_table "task_photos" do |t|
      t.string   "photo"
      t.integer  "task_id"

      t.timestamps
    end

    create_table "tasks" do |t|
      t.string   "title"
      t.string   "desc"

      t.timestamps
    end

    create_table "tasks_jointable", :id => false do |t|
      t.integer "m1_id"
      t.integer "m2_id"
    end

    create_table "photos" do |t|
      t.string "avatar"
      t.string "picture"
      t.integer "parentable_id"
      t.string "parentable_type"
      t.string "title"

      t.timestamps
    end
  end
end