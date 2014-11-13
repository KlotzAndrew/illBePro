class Ignindex < ActiveRecord::Base

 before_update :refresh_summoner

	def refresh_summoner
		self.update(summoner_validated: false)
		self.update(summoner_id: nil)
		self.update(validation_string: nil)
		self.update(validation_timer: nil)
	end

end
