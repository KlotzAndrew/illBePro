class UnhingeIgnindex < ActiveRecord::Migration
  def change
  	add_column :ignindices, :region_id, :integer
  	add_column :ignindices, :postal_code, :integer
  	add_column :ignindices, :last_validation, :integer
  	add_column :statuses, :ignindex_id, :integer
  	add_column :ignindices, :prize_id, :integer
  	add_column :ignindices, :ign_prize_level, :integer, default: 1
  	add_column :ignindices, :ign_challenge_points, :integer, default: 0
  	add_column :prizes, :ignindex_id, :integer
  end
end
