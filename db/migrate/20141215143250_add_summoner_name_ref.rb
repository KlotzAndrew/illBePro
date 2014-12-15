class AddSummonerNameRef < ActiveRecord::Migration
  def change
  	add_column :ignindices, :summoner_name_ref, :string
  end
end
