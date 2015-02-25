class AddCityToGeodeliver < ActiveRecord::Migration
  def change
  	add_column :geodelivers, :city, :string
  	add_column :prizes, :geo, :string
  end
end
