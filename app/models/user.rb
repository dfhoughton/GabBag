class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :notifications
  has_many :favorites
  has_many :friends
  has_many :anagrams, through: :favorites

  def subscribers
    return User.joins("INNER JOIN friends ON user_id = users.id").where "friends.other_id = :id AND friends.subscribed = :t", id: id, t: true
  end
end
