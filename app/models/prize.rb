class Prize < ActiveRecord::Base

has_many :prize_regions
has_many :regions, through: :prize_regions


has_one :user

# after_save :update_regions

# before_destroy :clean_region

def insert_prizes_manually
	Prize.find(dont_run)

h1 = ["5gopvb", "5axqil", "5aytfu", "5bcyoa", "5cofdl"]

h1.each do |x|
	  Prize.create(
    # :country_zone => "",
    :assignment => 0,
    :vendor => "Cora Pizza",
    :description => "$5 off",
    :reward_code => "",
    :tier => "2")
end

Achievement.delete_all
Ignindex.all.each do |x|
x.update(
:ign_challenge_points => 0)
if !x.active_achievement.nil?
x.update(
:active_achievement => nil)
end
end

1.times do |x|
  Prize.create(
    # :country_zone => "",
    :assignment => 0,
    :vendor => "Cora Pizza",
    :description => "$10 off",
    :reward_code => "C8V9",
    :tier => "1")
end; nil 

1.times do |x|
  Prize.create(
    # :country_zone => "",
    :assignment => 0,
    :vendor => "Cora Pizza",
    :description => "$5 off",
    :reward_code => "BR3Z",
    :tier => "2")
end; nil

postal_raw = ["M6G", "M6J", "M5R", "M5S", "M5T", "M5G"]
postal_regions = []
postal_raw.each do |x|
	postal_regions << Region.where("postal_code = ?", x).first.id
end; nil

Prize.all.each do |prize|
	postal_regions.each do |x|
	  prize.regions << Region.find(x)
	  prize.save
	end
end

prize = Prize.last
prize.regions

		h2 = [3687, 3688, 3689, 3690, 3691, 3692]
		
		h2.each do |x|
		  prize.regions << Region.find(x)
		  prize.save
		end

		Region.where("id < 100").each do |region|
		  prize.regions << region
		  prize.save
		end

		prize = Prize.find(id)
		prize.regions

		Region.where("id < 100").each do |region|
		  prize.regions << region
		  prize.save
		end		


	end



	def clean_region
		puts "cleaning regions..."
		puts "value: #{self.region_id != nil}"
		puts "prize: #{self.id}"
		if self.country_zone != nil
		else		
			if self.region_id != nil #stop json nil errors
				puts "Region IDs: #{JSON.parse(self.region_id)}"
				JSON.parse(self.region_id).each do |x|
					puts "Looking for #{x}"
				    region = Region.find_by_postal_code(x)  
				    puts "Region found postal: #{region.postal_code}"

				    if self.tier == "1"
				    	puts "its tier 1"
					    if region.prize_id_tier1 == nil
					    	#do nothing, region should already have prize_id and not be nil
					    	puts "issue with prizes already nil"
					    else
						    prize_string = JSON.parse(region.prize_id_tier1)
						    puts "got prize string: #{prize_string}"
						    if prize_string.include?(self.id) #if it is already there
							    prize_string = prize_string - [self.id]
							    puts "new prize string: #{prize_string}"
							    region.update(prize_id_tier1: prize_string.to_s)
						    end
					    end
				    elsif self.tier == "2"
					    if region.prize_id_tier2 == nil
					    	#do nothing, region should already have prize_id and not be nil
					    else
						    prize_string = JSON.parse(region.prize_id_tier2)
						    if prize_string.include?(self.id) #if it is already there
							    prize_string = prize_string - [self.id]
							    region.update(prize_id_tier2: prize_string.to_s)
						    end
					    end		    	
				    elsif self.tier == "3"
					    if region.prize_id_tier3 == nil
					    	#do nothing, region should already have prize_id and not be nil
					    else
						    prize_string = JSON.parse(region.prize_id_tier3)
						    if prize_string.include?(self.id) #if it is already there
							    prize_string = prize_string - [self.id]
							    region.update(prize_id_tier3: prize_string.to_s)
						    end
					    end		    	
				    elsif self.tier == "4"		    		    	
					end
				end
			end
		end
	end


	def update_regions

		if self.assignment == 0
			puts "prize: #{self.id}"
			if self.country_zone != nil
			else
				JSON.parse(self.region_id).each do |x|
			    region = Region.find_by_postal_code(x)  
			    	puts "region: #{region.postal_code}"
				    if region.vendor != self.vendor
				    	region.update(vendor: self.vendor)
				    end

				    puts "prize tier search: #{self.tier}"
				    puts "prize tier is == 1?: #{self.tier == "1"}"
				    if self.tier == "1"
				    	puts "prize tier found 1"
					    if region.prize_id_tier1 == nil
					    	puts "prize tier nil"
						    prize_string = []
						    prize_string << self.id
						    region.update(prize_id_tier1: prize_string.to_s)
					    else
					    puts "prize not nil"
					    prize_string = JSON.parse(region.prize_id_tier1)
					    puts "prize before string: #{prize_string}"
					    	if !prize_string.include?(self.id) #if its not there yet
					        	prize_string << self.id
					        	puts "prize after string: #{prize_string}"
					        	region.update(prize_id_tier1: prize_string.to_s)
					      	end
					    end
					elsif self.tier == "2"
					    if region.prize_id_tier2 == nil
						    prize_string = []
						    prize_string << self.id
						    region.update(prize_id_tier2: prize_string.to_s)
					    else
					    prize_string = JSON.parse(region.prize_id_tier2)
					    	if !prize_string.include?(self.id) #if its not there yet
					        	prize_string << self.id
					        	region.update(prize_id_tier2: prize_string.to_s)
					      	end
					    end					
					elsif self.tier == "3"
					    if region.prize_id_tier3 == nil
						    prize_string = []
						    prize_string << self.id
						    region.update(prize_id_tier3: prize_string.to_s)
					    else
					    prize_string = JSON.parse(region.prize_id_tier3)
					    	if !prize_string.include?(self.id) #if its not there yet
					        	prize_string << self.id
					        	region.update(prize_id_tier3: prize_string.to_s)
					      	end
					    end						
					elsif self.tier == "4"				
					end #just handled tier1

				end
			end

		elsif self.assignment == 2
			puts "prize: #{self.id}"
			if self.country_zone != nil
			else
				JSON.parse(self.region_id).each do |x|
				    region = Region.find_by_postal_code(x)  

				    if self.tier == "1"
					    if region.prize_id_tier1 == nil
					    	#do nothing, region should already have prize_id and not be nil
					    else
						    prize_string = JSON.parse(region.prize_id_tier1)
						    if prize_string.include?(self.id) #if it is already there
							    prize_string = prize_string - [self.id]
							    region.update(prize_id_tier1: prize_string.to_s)
						    end
					    end
					elsif self.tier == "2"
					    if region.prize_id_tier2 == nil
					    	#do nothing, region should already have prize_id and not be nil
					    else
						    prize_string = JSON.parse(region.prize_id_tier2)
						    if prize_string.include?(self.id) #if it is already there
							    prize_string = prize_string - [self.id]
							    region.update(prize_id_tier2: prize_string.to_s)
						    end
					    end					
					elsif self.tier == "3"
					    if region.prize_id_tier3 == nil
					    	#do nothing, region should already have prize_id and not be nil
					    else
						    prize_string = JSON.parse(region.prize_id_tier3)
						    if prize_string.include?(self.id) #if it is already there
							    prize_string = prize_string - [self.id]
							    region.update(prize_id_tier3: prize_string.to_s)
						    end
					    end						
					elsif self.tier == "4"					
					end
				end
			end
		end #end method

	end


end
