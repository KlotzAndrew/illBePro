class CreatePrizes < ActiveRecord::Migration
  def change
    create_table :prizes do |t|
      t.string :description
      t.string :tier
      t.string :vendor
      t.integer :code
      t.integer :assignment
      t.integer :user_id
      t.string :summoner_name    	
    
      t.timestamps
    end
  end
end
