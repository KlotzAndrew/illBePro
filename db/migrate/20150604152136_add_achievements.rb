class AddAchievements < ActiveRecord::Migration
  def change
    create_table :achievements do |t|
		t.string :description
		t.integer :ignindex_id
		t.integer :kind
		t.integer :result, default: nil

		t.integer :experience_req, default: 255
		t.integer :experience_earned, default: 0
		t.integer :games_played, default: 0
		t.integer :expire, default: nil

		t.boolean :require_wins, default: false
		t.string :can_spell_name, default: nil
		t.string :can_spell_name_open, default: nil
  

		t.timestamps
    end

  	add_column :ignindices, :active_achievement, :integer
  	add_column :statuses, :achievement_id, :integer  	
  end
end
