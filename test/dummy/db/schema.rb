# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120209045206) do

  create_table "habtm_name_tests", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "habtm_name_tests_tasks", :id => false, :force => true do |t|
    t.integer "task_id"
    t.integer "habtm_name_test_id"
  end

  create_table "hjoin_tests", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hjoin_tests_tasks", :id => false, :force => true do |t|
    t.integer "task_id"
    t.integer "hjoin_test_id"
  end

  create_table "hmany_fk_tests", :force => true do |t|
    t.integer  "something_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hmanythrough_joins", :force => true do |t|
    t.integer  "hmanythrough_test_id"
    t.integer  "task_id"
    t.string   "exdata"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hmanythrough_tests", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hone_as_tests", :force => true do |t|
    t.integer  "testable_id"
    t.string   "testable_type"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hone_tests", :force => true do |t|
    t.integer  "task_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
  end

  create_table "hook_tests", :force => true do |t|
    t.string   "title"
    t.string   "foo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "moderations", :force => true do |t|
    t.integer  "moderatable_id"
    t.string   "moderatable_type",               :null => false
    t.string   "attr_name",        :limit => 60, :null => false
    t.text     "attr_value",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photo_holders", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photo_relateds", :force => true do |t|
    t.integer  "photo_id"
    t.string   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photos", :force => true do |t|
    t.string   "photo"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "photo_holder_id"
  end

  create_table "subtasks", :force => true do |t|
    t.integer  "task_id"
    t.string   "title"
    t.string   "desc"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "task_all_id"
  end

  create_table "task_alls", :force => true do |t|
    t.string   "title"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
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

end
