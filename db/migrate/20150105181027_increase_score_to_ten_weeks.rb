class IncreaseScoreToTenWeeks < ActiveRecord::Migration
  def change
  	add_column :scores, :week_5, :integer, default: 0
  	add_column :scores, :week_6, :integer, default: 0
  	add_column :scores, :week_7, :integer, default: 0
  	add_column :scores, :week_8, :integer, default: 0
  	add_column :scores, :week_9, :integer, default: 0
  	add_column :scores, :week_10, :integer, default: 0
	add_column :scores, :week_11, :integer, default: 0
  end
end
