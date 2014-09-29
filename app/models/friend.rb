class Friend < ActiveRecord::Base
  belongs_to :user
  belongs_to :other, :class_name => 'User'

  # whether the friendship is mutual; returns the opposite relation or nil
  def mutual
    @mutual ||= other.friends.where(other: user).take
    return @mutual
  end
end
