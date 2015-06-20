class Ignindex < ActiveRecord::Base

	# belongs_to :user // ignindex now floats for 'temporary' users w/o user_id
	has_many :statuses
	belongs_to :region
	has_many :achievements

	def refresh_summoner
		# self.update(summoner_validated: false)
		# self.update(summoner_id: nil)
		self.update(validation_string: nil)
		self.update(validation_timer: nil)
	end

	def refresh_validation
		self.update(validation_timer: "#{Time.now.to_i}")
		self.update(validation_string: "#{"pizza-" + ('a'..'z').to_a.shuffle.first(4).join}")
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
