FactoryGirl.define do
  factory :achievement do
  	challenge_id 1
  end

  	trait :cora_pizza_challenge_part do
	  	merchant "Cora Pizza"
		name "Cora Pizza Challenge"
		has_prizing true
		can_spell_name "CORA"
		can_spell_name_open "COR"
		wins_required 10
		wins_recorded 1
  	end

end