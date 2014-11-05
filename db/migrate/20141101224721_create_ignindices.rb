class CreateIgnindices < ActiveRecord::Migration
  def change
    create_table :ignindices do |t|
      t.integer :owner_id
      t.string :summoner_name
      t.integer :summoner_id
      t.boolean :summoner_validated
      t.string :validation_string
      t.integer :validation_timer

      t.timestamps
    end
  end
end
