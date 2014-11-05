class CreateScores < ActiveRecord::Migration
  def change
    create_table :scores do |t|
      t.integer :user_id
      t.string :summoner_name
      t.integer :summoner_id
      t.integer :week_1
      t.integer :week_2
      t.integer :week_3
      t.integer :week_4

      t.timestamps
    end
  end
end
