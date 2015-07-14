class CreateChallengeRegions < ActiveRecord::Migration
  def change
    create_table :challenge_regions do |t|
    	t.integer :region_id, null: false
    	t.integer :challenge_id, null: false    	

      t.timestamps
    end
  end
end
