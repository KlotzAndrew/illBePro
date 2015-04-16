class AddProcChance < ActiveRecord::Migration
  def change
  	add_column :statuses, :proc_value, :integer, default: 0
  	add_column :statuses, :roll_status, :integer, default: 0
  end
end
