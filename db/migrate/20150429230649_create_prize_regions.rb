class CreatePrizeRegions < ActiveRecord::Migration
  def change
    create_table :prize_regions do |t|
    	t.integer :region_id, null: false
    	t.integer :prize_id, null: false
    	t.timestamps
    end
  end
end
