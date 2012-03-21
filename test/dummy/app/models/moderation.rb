class Moderation < ActiveRecord::Base
  belongs_to :moderatable, :polymorphic => true
  
  include HasModerated::ModerationModel
end
