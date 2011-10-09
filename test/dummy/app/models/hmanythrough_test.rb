class HmanythroughTest < ActiveRecord::Base
  has_many :hmanythrough_join
  has_many :tasks, :through => :hmanythrough_join
end
