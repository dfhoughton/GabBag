class CreatePhrases < ActiveRecord::Migration
  def change
    create_table :phrases do |t|
      t.string :text, :unique => true

      t.timestamps
    end
  end
end
