class Score < ActiveRecord::Base

	def self.open_achievments_since(start_date)
	    all_open = []
	    Ignindex.all.includes(:achievements).where("updated_at > ?", Time.at(start_date)).where.not("summoner_name IS ?", nil).where.not("active_achievement IS ?", nil).each do |x|
	      achievement = Achievement.find(x.active_achievement)
	      points = 0
	      points_total = 0

	      if !achievement.challenge.wins_required.nil?
	      	Rails.logger.info "achievement: #{achievement}"
	      	Rails.logger.info "points: #{points}"
	      	Rails.logger.info "achievement.wins_recorded: #{achievement.wins_recorded}"
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

	def prize_history
      if !ignindex.nil? && ignindex.summoner_validated == true
        
        @uu_summoner_validated = true
        @history = Prize.all.where("ignindex_id = ?", ignindex.id).where("assignment = ?", 2).order(created_at: :desc)

        if !ignindex.prize_id.nil? #send me to a mehtod
          @ignindex = ignindex
          prize = Prize.find(ignindex.prize_id)
          @prize_description = prize.description
          @prize_vendor = prize.vendor
          @prize_code = prize.code
          @prize_reward_code = prize.reward_code
        end

      end
	end

	

end
