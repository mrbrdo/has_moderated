class InitialSchema < ActiveRecord::Migration
  def change
    create_table "moderations", :force => true do |t|
      t.integer  "moderatable_id"
      t.string   "moderatable_type"
      t.text     "data",             :null => false
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    create_table "subtasks", :force => true do |t|
      t.integer  "task_id"
      t.string   "title"
      t.string   "desc"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "parentable_id"
      t.string   "parentable_type"
    end

    create_table "task_connections", :force => true do |t|
      t.string   "title"
      t.integer  "m1_id"
      t.integer  "m2_id"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "task_photos", :force => true do |t|
      t.string   "photo"
      t.integer  "task_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tasks", :force => true do |t|
      t.string   "title"
      t.string   "desc"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tasks_jointable", :id => false, :force => true do |t|
      t.integer "m1_id"
      t.integer "m2_id"
    end
  end
end
