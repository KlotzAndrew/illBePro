class StatusQueueNumberWinDesc < ActiveRecord::Migration
  def change
  	add_column :statuses, :win_value, :integer
  	add_column :statuses, :queue_number, :integer
  	add_column :statuses, :challenge_description, :string
  end
end
