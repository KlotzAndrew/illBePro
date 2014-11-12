class AddScoresToStatus < ActiveRecord::Migration
  def change
  	add_column :statuses, :kind, :integer
  	add_column :statuses, :points, :integer
  	add_column :statuses, :challenge_description, :string
  	add_column :statuses, :win_value, :integer
  end
end
