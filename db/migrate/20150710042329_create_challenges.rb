class CreateChallenges < ActiveRecord::Migration
  def change
    create_table :challenges do |t|
    	t.string :merchant
    	t.integer :kind
    	t.boolean :available
    	t.integer :expiery
    	t.string :name
        t.boolean :global

        t.boolean :global_prizing
    	t.boolean :local_prizing
    	t.string :can_spell_name
    	t.integer :wins_required

      t.timestamps
    end

    add_column :achievements, :challenge_id, :integer
    add_column :achievements, :region_id, :integer
    add_column :achievements, :has_prizing, :boolean, default: false

    add_column :achievements, :wins_required, :integer, default: 0
    add_column :achievements, :wins_recorded, :integer
    add_column :achievements, :name, :string
    add_column :achievements, :merchant, :string    

    
  end
end
