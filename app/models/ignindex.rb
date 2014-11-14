class Ignindex < ActiveRecord::Base


	def refresh_summoner
		self.update(summoner_validated: false)
		self.update(summoner_id: nil)
		self.update(validation_string: nil)
		self.update(validation_timer: nil)
	end

	def refresh_validation
		if Ignindex.where("validation_string > ?", 0).count >= 5
			errors.add(:challenge_hampster, ' is overloaded with other challenges! Try back in a few minutes')
		else
			self.update(validation_timer: "#{Time.now.to_i}")
			self.update(validation_string: "#{('a'..'z').to_a.shuffle.first(6).join}")
		end
	end

end
