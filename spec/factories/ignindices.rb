FactoryGirl.define do

  factory :ignindex do

  	trait :validated do
  		summoner_validated true
  		region_id 1
  	end

  	trait :timer_on do
  		validation_timer Time.now.to_i
  	end

  	trait :timer_off do
  		validation_timer Time.now.to_i - 701
  	end

  	trait :theoddone do
  		summoner_name "TheOddOne"
		summoner_name_ref "theoddone"
  	end

  	trait :boxstripe do
  		summoner_name "BoxStripe"
		summoner_name_ref "boxstripe"
  	end

  	trait :nightblue3 do
  		summoner_name "Nightblue3"
		summoner_name_ref "nightblue3"
  	end  	

  	trait :theoddone_id do
  		summoner_id 60783
  	end

  	trait :boxstripe_id do
  		summoner_id 51189734
  	end

  	trait :nightblue3_id do
  		summoner_id 25850956
  	end  	

  	trait :theoddone_page1 do
  		validation_string "TIME MAN"
  	end
  end

end