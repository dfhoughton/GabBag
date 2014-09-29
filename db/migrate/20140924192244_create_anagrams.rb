class CreateAnagrams < ActiveRecord::Migration
  def change
    create_table :anagrams do |t|
      t.references :phrase, index: true
      t.references :child, index: true

      t.timestamps
    end
  end
end
