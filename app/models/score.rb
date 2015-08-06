class Score < ActiveRecord::Base

	def self.open_achievments_since(start_date)
	    all_open = []
	    Ignindex.all.includes(:achievements).where("updated_at > ?", Time.at(start_date)).where.not("summoner_name IS ?", nil).where.not("active_achievement IS ?", nil).each do |x|
	      achievement = Achievement.find(x.active_achievement)
	      points = 0
	      points_total = 0

	      if !achievement.challenge.wins_required.nil?
	        points += achievement.wins_recorded
	        points_total += achievement.challenge.wins_required
	      end

	      if !achievement.challenge.can_spell_name.nil?
	        points += (achievement.can_spell_name.length - achievement.can_spell_name_open.length)
	        points_total += achievement.can_spell_name.length
	      end

	      if !achievement.challenge.con_wins_required.nil?
	        points += achievement.con_wins_recorded
	        points_total += achievement.challenge.con_wins_required
	      end          

	      if points_total == 0
	        points_total = 1
	      end
	      
	      number = points/points_total.round(2)
	      progress = (number.round(2)*100).round(0)

	      block = []
	      block << x.ign_challenge_points
	      block << x.summoner_name
	      block << achievement
	      block << progress
	      all_open << block
	    end
	    all_open = all_open.sort_by{|a,b,c,d| [a,d]}.reverse
	    return all_open
	end




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
