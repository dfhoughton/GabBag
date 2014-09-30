require 'json'
require 'set'

class NotificationsController < ApplicationController
  before_action :authenticate_user!

  # called by poller: notifications the poller hasn't yet received
  def recent
    notifications = cull fetch()
    render json: notifications
  end

  # called on page load: notifications requiring display
  def unread
    notifications = cull fetch(:read), 'subscribe', 'friend'
    render json: notifications
  end

  private

  # fetch the right variety of the current user's notifications
  def fetch(field = :received)
    recent = current_user.notifications.where field => [false, nil]
    notifications = recent.map { |n| jsonize(n) }
    recent.update_all received: true
    return notifications
  end

  # remove duplicate notifications from the list and ignore dumpable notifications
  def cull(notifications, *dump)
    dump = Set.new dump
    seen = {}
    keep = []
    notifications.reverse.each do |body|
      t = body['type']
      if dump.include? t
        body['notification'].update read: true
        next
      end
      type = seen[t] ||= {}
      case t
        when 'share'
          id = body['anagram']['id']
          if type[id]
            body['notification'].destroy
          else
            body.delete 'notification'
            keep << body
            type[id] = true
          end
        when 'friend', 'subscribe'
          id = body['from']
          change = body['change']
          if type[id]
            if change != type[id][:last]
              type[id][:last] = change
              type[id][:tally] += change
            end
          else
            type[id] = {last: change, tally: change}
          end
          body['notification'].update :read => true
          body.delete 'notification'
          keep << body
        else
          raise "unhandled type: #{body['type']}"
      end
    end
    set = Set.new
    keep.select! do |body|
      type = body['type']
      case type
        when 'share'
          true
        when 'friend', 'subscribe'
          id = body['from']
          if set.include? id
            false
          else
            set.add id
            tally = seen[type][id][:tally]
            if tally == 0
              false
            else
              body['change'] = tally
              true
            end
          end
      end
    end
    return keep.reverse
  end

  def jsonize(n)
    body = JSON.parse n.body
    body['read'] = n.read
    body['notification'] = n
    return body
  end
end
