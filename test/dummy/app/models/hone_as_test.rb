class HoneAsTest < ActiveRecord::Base
  belongs_to :testable, :polymorphic => true
end
