class AddClassesToPrizes < ActiveRecord::Migration
  def change
  	add_column :prizes, :country_zone, :string
  	add_column :prizes, :province_zone, :string
  end
end
