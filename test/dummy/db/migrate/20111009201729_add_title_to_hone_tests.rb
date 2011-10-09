class AddTitleToHoneTests < ActiveRecord::Migration
  def change
    add_column :hone_tests, :title, :string
  end
end
