class Notifications < ActionMailer::Base
  default from: "dfhoughton+anagrams@gmail.com"
  def welcome(user)
    @user = user
  end
end
