class Challenge < ActiveRecord::Base
	has_many :achievements
	
	has_many :challenge_regions
	has_many :regions, :through => :challenge_regions

	def built_challenges
		Challenge.find(dont_run)
		
		Challenge.create(
		  :merchant => "Cora Pizza",
		  :available => true,
		  :expiery => (Time.now.to_i + 4.weeks.to_i),
		  :name => "Cora Pizza Challenge",
		  :global => false,
		  :global_prizing => false,
		  :local_prizing => true,
		  :can_spell_name => "CORA",
		  :wins_required => 10)

		Challenge.create(
		  :merchant => "Cora Pizza",
		  :available => true,
		  :expiery => (Time.now.to_i + 4.weeks.to_i),
		  :name => "Cora Pizza Challenge",
		  :global => true,
		  :global_prizing => false,
		  :local_prizing => false,
		  :can_spell_name => "CORA",
		  :wins_required => 10)

		Challenge.create(
		  :merchant => "illBePro",
		  :available => true,
		  :expiery => (Time.now.to_i + 4.weeks.to_i),
		  :name => "Win 10 Games",
		  :global => true,
		  :global_prizing => false,
		  :local_prizing => false,
		  :can_spell_name => nil,
		  :wins_required => 10)

		Challenge.create(
		  :merchant => "illBePro",
		  :available => true,
		  :expiery => (Time.now.to_i + 4.weeks.to_i),
		  :name => "Hot Streak",
		  :global => true,
		  :global_prizing => false,
		  :local_prizing => false,
		  :can_spell_name => nil,
		  :wins_required => nil,
		  :con_wins_required => 3)

		Challenge.create(
		  :merchant => "Papa John's",
		  :available => true,
		  :expiery => (Time.now.to_i + 4.weeks.to_i),
		  :name => "Papa John's Challenge",
		  :global => false,
		  :country => "US",
		  :global_prizing => false,
		  :local_prizing => true,
		  :can_spell_name => "PAPAJOHNS",
		  :wins_required => 3,
		  :con_wins_required => nil)		
	end
end
