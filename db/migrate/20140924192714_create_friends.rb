class CreateFriends < ActiveRecord::Migration
  def change
    create_table :friends do |t|
      t.references :user, index: true
      t.references :other, index: true

      t.timestamps
    end
  end
end
