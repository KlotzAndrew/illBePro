class FixUserSummName < ActiveRecord::Migration
  def change
  	add_column :users, :summoner_name, :string
  end
end
