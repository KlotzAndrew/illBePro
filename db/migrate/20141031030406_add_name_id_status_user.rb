class AddNameIdStatusUser < ActiveRecord::Migration
  def change
  	add_column :statuses, :summoner_name, :string
   end
end
