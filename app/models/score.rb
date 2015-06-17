class Score < ActiveRecord::Base

  def assign_prize(choice) #move this to m/prize.rb
  	if choice == "Accept" or choice == "Upgrade"
	prize = Prize.find(self.prize_id)
	    if self.ignindex_id == prize.ignindex_id #double check prize is assigned correctly

	    	if choice == "Accept" or self.prize_level == 3
		      prize.update(
		      	:assignment => 2,
		      	:delivered_at => Time.now.to_i) #this is a double net
		      self.update(
		      	:prize_id => nil,
		      	:last_prize_time => Time.now.to_i,
		      	:challenge_points => 0)
		      	#:prize_level => 1)

	      	elsif choice == "Keep Playing"
		      prize.update(
		      	:assignment => 0,
		      	:ignindex_id => nil)
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
