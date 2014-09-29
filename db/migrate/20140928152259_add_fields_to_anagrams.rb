class AddFieldsToAnagrams < ActiveRecord::Migration
  def change
    change_table :anagrams do |t|
      t.integer :favored, :default => 0
      t.integer :shared, :default => 0
    end
  end
end
