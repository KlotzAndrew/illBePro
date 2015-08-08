FactoryGirl.define do

  factory :challenge do

  	trait :hotstreak do
		merchant "illBePro"
		available true
		expiery Time.now.to_i + 4.weeks.to_i
		name "Hot Streak"
		global true
		global_prizing false
		local_prizing false
		can_spell_name nil
		wins_required nil
		con_wins_required 3
  	end

  	trait :cora_pizza_challenge do
	  	merchant "Cora Pizza"
		available true
		expiery Time.now.to_i + 4.weeks.to_i
		name "Cora Pizza Challenge"
		global false
		global_prizing false
		local_prizing true
		can_spell_name "CORA"
		wins_required 10
  	end

  	trait :global do
  		global true
  	end

  	trait :country do
  		global false
  		country "CA"
  	end

  	trait :local do
  		global false
  	end
  end

end