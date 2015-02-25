class CreateRegions < ActiveRecord::Migration
  def change
    create_table :regions do |t|
      t.string :postal_code
      t.string :city
      t.float :lat
      t.float :long
      t.string :country
      t.string :province

      t.string :active
      t.string :vendor



      t.timestamps
    end
  end
end
