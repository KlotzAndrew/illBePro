class ChangePostalClass < ActiveRecord::Migration
  def self.up
    change_column :ignindices, :postal_code, :string
  end
 
  def self.down
    change_column :ignindices, :postal_code, :integer
  end
end
