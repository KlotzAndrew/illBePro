class Champion < ActiveRecord::Base

	def self.update_champions
		p = 1
		puts p
		while p < 500
			if Champion.where(id: p).empty?
				Champion.create(:id => p)
			end
			champion = Champion.find(p)
			if champion.champion.nil?
				begin
					url = "https://na.api.pvp.net/api/lol/static-data/na/v1.2/champion/#{p}?api_key=" + + Rails.application.secrets.league_api_key
					remote5_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
					champion_hash = JSON.parse(remote5_data)
					Champion.find(p).update(champion: "#{champion_hash["key"]}")
					puts champion_hash["key"]
				rescue OpenURI::HTTPError => ex
					puts "KANYE for #{p}"
				end
			end
			p += 1
		end
	end

end
