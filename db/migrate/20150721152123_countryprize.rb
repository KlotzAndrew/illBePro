class Countryprize < ActiveRecord::Migration
  def change
  	add_column :challenges, :country, :string
  end
end
