class Geodeliver < ActiveRecord::Migration
  def change
    create_table :geodelivers do |t|
    	t.integer :user_id
    	t.string :ip_address
    	t.float :latitude
    	t.float :longitude
      t.string :country_code
      t.string :postal_code

      t.string :address



      t.timestamps
    end
  end
end
