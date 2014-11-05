class AddSummoneridUserStatus < ActiveRecord::Migration
  def change
  	add_column :statuses, :summoner_id, :integer
  	add_column :users, :summoner_id, :integer
  end
end
