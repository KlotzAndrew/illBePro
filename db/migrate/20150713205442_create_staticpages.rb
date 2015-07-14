class CreateStaticpages < ActiveRecord::Migration
  def change
    create_table :staticpages do |t|
    	t.integer :league_api_ping, default: 1
    	t.string :league_notes
    	t.string :news

      t.timestamps
    end
  end
end
