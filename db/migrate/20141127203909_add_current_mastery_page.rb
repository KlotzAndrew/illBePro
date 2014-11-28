class AddCurrentMasteryPage < ActiveRecord::Migration
  def change
  	add_column :ignindices, :mastery_1_name, :string
  end
end
