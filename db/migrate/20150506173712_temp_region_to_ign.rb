class TempRegionToIgn < ActiveRecord::Migration
  def change
  	add_column :ignindices, :region_id_temp, :integer
  	add_column :users, :ignindex_id, :integer

  	change_column :ignindices, :postal_code, :string
  end
end
