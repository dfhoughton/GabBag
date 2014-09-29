require 'json'

class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def recent
    recent = current_user.notifications.where received: false
    notifications = recent.map { |n| notifications << jsonize(n) }
    current_user.notifications.update_all received: true
    cull! notifications
    render json: notifications
  end

  def all
    notifications = current_user.notifications.map { |n| notifications << jsonize(n) }
    current_user.notifications.update_all received: true
    cull! notifications
    render json: notifications
  end

  # remove duplicate notifications from the list
  def cull!(notifications)
    seen = {}
    keep = []
    notifications.reverse.each do |body|
      type = seen[body[:type]] ||= {}
      case body[:type]
        when :share
          id = body[:anagram][:id]
          if type[id]
            body[:notification].destroy
          else
            body.delete :notification
            keep << body
            type[id] = true
          end
        when :friend
          id = body[:id]
          change = body[:change]
          if type[id]
            if change != type[id][:last]
              type[id][:last] = change
              type[id][:tally] += change
            end
          else
            type[id] = { last: change, tally: change }
          end
          body.delete :notification
        when :subscribe
          id = body[:id]
          change = body[:change]
          if type[id]
            if change != type[id][:last]
              type[id][:last] = change
              type[id][:tally] += change
            end
          else
            type[id] = { last: change, tally: change }
          end
          body.delete :notification
        else
          raise "unhandled type: #{body[:type]}"
      end
    end
    keep.select! do |body|
      type = body[:type]
      if type == 'share'
        true
      elsif type == 'friend' || type == 'subscribe'
        seen[type][body[:id]][:tally] != 0
      end
    end
    notifications.clear
    notifications += keep.reverse
  end

  def jsonize(n)
    body = JSON.parse n.body
    body[:read] = n.read
    body[:notification] = n
    return body
  end
end
