class SimplifyNotifications < ActiveRecord::Migration
  def change
    change_table :notifications do |t|
      t.remove :source
      t.remove :anagram
      t.remove :pushed
      t.column :body, :string
    end
  end
end
