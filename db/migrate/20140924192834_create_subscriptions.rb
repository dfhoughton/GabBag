class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :user, index: true
      t.references :source, :class_name => 'User'

      t.timestamps
    end
  end
end
