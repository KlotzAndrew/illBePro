class UserGamesHash < ActiveRecord::Migration
  def change
  	add_column :statuses, :api_ping, :integer
  	add_column :statuses, :game_1, :text
  	add_column :statuses, :game_2, :text
  	add_column :statuses, :game_3, :text
  	add_column :statuses, :game_4, :text
  	add_column :statuses, :game_5, :text
  end
end
