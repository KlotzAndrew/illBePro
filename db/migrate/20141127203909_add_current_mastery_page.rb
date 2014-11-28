class AddCurrentMasteryPage < ActiveRecord::Migration
  def change
  	add_column :Ignindices, :mastery_1_name, :string
  end
end
