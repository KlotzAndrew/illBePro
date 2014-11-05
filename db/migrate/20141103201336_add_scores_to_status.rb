class AddScoresToStatus < ActiveRecord::Migration
  def change
  	add_column :statuses, :kind, :integer
  	add_column :statuses, :points, :integer
  end
end
