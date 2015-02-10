class CreateGeodelivers < ActiveRecord::Migration
  def change
    create_table :geodelivers do |t|

      t.timestamps
    end
  end
end
