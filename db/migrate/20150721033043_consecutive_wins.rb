class ConsecutiveWins < ActiveRecord::Migration
  def change
  	add_column :challenges, :con_wins_required, :integer
  	add_column :achievements, :con_wins_recorded, :integer
  end
end
