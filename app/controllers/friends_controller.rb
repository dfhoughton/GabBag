class FriendsController < ApplicationController
  before_action :authenticate_user!
  # the current user's friends
  def mine
    friends = Friend.where "user_id = :id OR other_id = :id ", {:id => current_user.id}
    map = {} # a map from others to their relationships
    friends.each do |f|
      id = f.user_id == current_user.id ? f.other_id : f.user_id
      map[id] ||= []
      map[id] << f
    end
    data = []
    friends.each do |f|
      own = f.user_id == current_user.id
      other = own ? f.other_id : f.user_id;
      rels = map[other]
      mutual = rels.length == 2
      next if mutual && !own
      email = own ? f.other.email : f.user.email
      datum = {own: own, id: f.id, email: email, mutual: mutual}
      if mutual
        not_this = rels.select{ |o| o.id != f.id }[0]
        me, them = f, not_this
        me, them = not_this, f if !own
        datum[:other_id] = them.id
        datum[:subscribed_to_them] = me.subscribed
        datum[:subscribed_to_me] = them.subscribed
      else
        datum[own ? :subscribed_to_them : :subscribed_to_me] = f.subscribed
      end
      data << datum
    end
    render json: {friends: data}
  end

  # finds users who are not yet friends
  def prospects
    query = params[:query]
    subquery = Friend.select(:other_id).where(:user_id => current_user.id).to_sql
    condition = "other_id IS NULL AND id != :id AND email LIKE :infix"
    join = "LEFT OUTER JOIN (#{subquery}) ON id = other_id"
    query = User.joins(join).where(condition, {:id => current_user.id, :infix => "%#{query}%"})
    prospects = query.select(:email, :id).map { |u| u.as_json }
    render json: {:prospects => prospects}
  end

  # records a friend relationship
  def create
    friend = Friend.create user_id: current_user.id, other_id: params[:id]
    o = friend.other
    datum = {id: friend.id, email: o.email, own: true}
    f = o.friends.where(:other_id => current_user.id).take
    if f
      datum[:subscribed_to_me] = f.subscribed
      datum[:mutual] = true
      datum[:other_id] = f.id
    end
    # notify the new friend
    message = {
        type: 'friend',
        id: current_user.id,
        email: current_user.email,
        change: 1 # add a friendship
    }
    Notification.create user: o, body: message.to_json
    render json: datum
  end

  # for toggling the subscription state on and off
  # TODO handle error state where friend does not exist
  def update
    friend = Friend.find params[:id]
    subscribed = params[:subscribed] == 1
    friend.update subscribed: subscribed
    message = {
        type: 'subscribe',
        id: current_user.id,
        email: current_user.email,
        change: subscribed ? 1 : -1
    }
    Notification.create user: friend.other, body: message.to_json
    render json: {success: subscribed == friend.subscribed}
  end

  # ends friendship
  # TODO handle error state where friend does not exist
  def destroy
    friend = Friend.find params[:id]
    success = friend.destroy
    if success
      message = {
          type: 'friend',
          id: current_user.id,
          email: current_user.email,
          change: -1
      }
      Notification.create user: friend.other, body: message.to_json
    end
    render json: {success: success}
  end
end
