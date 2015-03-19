class Prize < ActiveRecord::Base

has_many :regions

has_one :user

after_save :update_regions

before_destroy :clean_region

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
