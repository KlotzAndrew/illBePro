class AddPrizeIdToRegion < ActiveRecord::Migration
  def change
  	  	add_column :regions, :prize_id_tier1, :string
  	  	add_column :regions, :prize_id_tier2, :string
  	  	add_column :regions, :prize_id_tier3, :string
  	  	add_column :regions, :prize_id_tier4, :string
  	  	add_column :prizes, :region_id, :string
        add_column :prizes, :delivered_at, :integer
  	  	add_column :ignindices, :prize_token, :integer
    	add_column :scores, :prize_level, :integer, default: 1
    	add_column :scores, :challenge_points, :integer, default: 0
    	add_column :scores, :last_prize_time, :integer, default: 0
      add_column :scores, :prize_id, :integer
      add_column :statuses, :prize_id, :integer
      add_column :geodelivers, :region_id, :integer

  end
end
