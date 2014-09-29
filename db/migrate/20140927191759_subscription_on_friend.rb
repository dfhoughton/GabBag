class SubscriptionOnFriend < ActiveRecord::Migration
  def change
    change_table :friends do |t|
      t.boolean :subscribed, :default => false
    end
  end
end
