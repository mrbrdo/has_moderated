class HmanythroughJoin < ActiveRecord::Base
  belongs_to :task
  belongs_to :hmanythrough_test
end
