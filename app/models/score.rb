class Score < ActiveRecord::Base

  after_create :build_scorecard

  def assign_prize(choice)
  	if choice == "Accept" or choice == "Upgrade"
	prize = Prize.find(self.prize_id)
	    if self.user_id == prize.user_id #double check prize is assigned correctly

	    	if choice == "Accept" or self.prize_level == 3
		      prize.update(
		      	:assignment => 2,
		      	:delivered_at => Time.now.to_i)
		      self.update(
		      	:prize_id => nil,
		      	:last_prize_time => Time.now.to_i,
		      	:challenge_points => 0)
		      	#:prize_level => 1)

	      	elsif choice == "Upgrade"
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


  def build_scorecard
  	self.update()
  end

end
