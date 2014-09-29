class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :source, :class_name => 'User'
end
