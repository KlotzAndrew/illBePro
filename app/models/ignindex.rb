class Ignindex < ActiveRecord::Base

	# belongs_to :user // ignindex now floats for 'temporary' users w/o user_id
	has_many :statuses
	belongs_to :region
	has_many :achievements

	# def update_region_id(dirty_postal) #line 17 & 26 are creating when not required
	# 	Rails.logger.info "method postal: #{self.postal_code}, dity_postal: #{dirty_postal}"
	# 	postal_search = dirty_postal.to_s

	# 	#auto-detect where the postal code is from + format it for search
	# 	Rails.logger.info "us?: #{!/[0-9]/.match(postal_search[0]).nil?}"
	# 	Rails.logger.info "ca?: #{!/[a-zA-Z]/.match(postal_search[0]).nil?}"
	# 	if !/[0-9]/.match(postal_search[0]).nil? #this is a zip code
	# 		if postal_search.length > 5
	# 			postal_search = postal_search[0..4]
	# 		end
	# 		if !Region.where("postal_code = ?", postal_search).first.nil?
	# 			self.update(region_id_temp: Region.where("postal_code = ?", postal_search).first.id)
	# 		end
	# 		Rails.logger.info "US: #{postal_search}"
	# 		Rails.logger.info "US: #{self.region_id_temp}"
	# 	elsif !/[a-zA-Z]/.match(postal_search[0]).nil? #this is a postal code
	# 		if postal_search.length >= 3
	# 			postal_search = postal_search[0..2].upcase
	# 		end	
	# 		if !Region.where("postal_code = ?", postal_search).first.nil?
	# 			self.update(region_id_temp: Region.where("postal_code = ?", postal_search).first.id)
	# 		end
	# 		Rails.logger.info "CA: #{postal_search}"
	# 		Rails.logger.info "CA: #{self.region_id_temp}"
	# 	else

	# 		Rails.logger.info "alkatraz"
	# 		#error entering postal code!
	# 	end
	# 	Rails.logger.info "#postal_search: #{postal_search}"
	# 	# Rails.logger.info "region_id: #{Region.where("postal_code = ?", postal_search).first.id}"
	# 	# self.update(
	# 	# 	:region_id => Region.where("postal_code = ?", self.postal_code).first.id)
	# end

	def refresh_summoner
		# self.update(summoner_validated: false)
		# self.update(summoner_id: nil)
		self.update(validation_string: nil)
		self.update(validation_timer: nil)
	end

	def refresh_validation
		self.update(validation_timer: "#{Time.now.to_i}")
		self.update(validation_string: "#{('a'..'z').to_a.shuffle.first(5).join}")
	end

	def self.prize_objects(ignindex_id)
		prize_2 = Ignindex.find(ignindex_id).summoner_name
		
	end


  def assign_prize(choice)
  	if choice == "Accept" or choice == "Upgrade"
		prize = Prize.find(self.prize_id)
		Rails.logger.info "Prize choice was #{choice}"
		Rails.logger.info "self.prize_id: #{self.prize_id}, prize.ignindex_id: #{prize.ignindex_id}"
	    if self.id == prize.ignindex_id #double check prize is assigned correctly

	    	if choice == "Accept"
	    		Rails.logger.info "choice is confirm accept"
		      prize.update(
		      	:assignment => 2,
		      	:delivered_at => Time.now.to_i)
		      self.update(
		      	:prize_id => nil,
		      	:last_prize_time => Time.now.to_i)
		      	#:prize_level => 1)

	      	elsif choice == "Upgrade"

	    		Rails.logger.info "choice is confirm accept"
		      prize.update(
		      	:assignment => 0,
		      	:user_id => nil)
		      self.update(
		      	:prize_id => nil)
		      	#:challenge_points => 0
		      	#:prize_level => self.prize_level + 1)	      		
	      	else
	      	end
	    else
	      #something is wrong
	    end
	else
		Rails.logger.info "vars going in wrong"
	end
  end	

end
