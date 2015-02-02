class AddPrizeControlsForIgnindex < ActiveRecord::Migration
  def change
  	add_column :ignindices, :prize_level, :integer, default: 0
	add_column :ignindices, :challenge_points_1, :integer, default: 0
	add_column :ignindices, :challenge_points_2, :integer, default: 0
	add_column :ignindices, :challenge_points_3, :integer, default: 0
	add_column :ignindices, :last_prize_time, :integer, default: 0
  end
end
