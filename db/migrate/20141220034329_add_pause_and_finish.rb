class AddPauseAndFinish < ActiveRecord::Migration
  def change
  	add_column :statuses, :pause_timer, :integer
  	add_column :statuses, :trigger_timer, :integer
  end
end
