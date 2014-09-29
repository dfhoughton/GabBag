class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :user, index: true
      t.references :source, index: true
      t.references :anagram, index: true
      t.boolean :pushed
      t.boolean :received
      t.boolean :read

      t.timestamps
    end
  end
end
