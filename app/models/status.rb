class Status < ActiveRecord::Base

	belongs_to :user
	
	validates :user_id, presence: true
	#no validation on length/presence

  def self.update_value
    Rails.logger.info "*****Started cron at #{Time.now}*****"
    d = Time.now
    api_call_count = 0
    val_count = 0
    Ignindex.where("validation_timer > ?", 0 ).each do |x|
        if x.validation_timer < (Time.now.to_i - 300)
        x.update(validation_timer: nil)
        x.update(validation_string: nil)
        Rails.logger.info "#{x.id} ran out of time"
      else
        Rails.logger.info "#{x.summoner_name} still has #{300 + x.validation_timer - Time.now.to_i} seconds!"

        if x.summoner_id.nil?
          Rails.logger.info "update id for #{x.summoner_name}"
          sleep 0.8
          url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/#{x.summoner_name}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
          val_count += 1
          summoner_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
          summoner_hash = JSON.parse(summoner_data)
          summoner_hash["#{Ignindex.last.summoner_name.downcase}"]["id"]
          x.update(summoner_id: summoner_hash["#{Ignindex.last.summoner_name.downcase}"]["id"])
        else
          Rails.logger.info "no update id for #{x.summoner_name}"
        end

        sleep 0.8
        url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/#{x.summoner_id}/masteries?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
        val_count += 1
        mastery_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
        mastery_hash = JSON.parse(mastery_data)
        name = mastery_hash["#{x.summoner_id}"]["pages"][0]["name"]
        Rails.logger.info "1st page name: #{name}; should be: #{x.validation_string}"

        if name == x.validation_string
          if Ignindex.where(summoner_id: x.summoner_id).where(summoner_validated: true).count > 1
            Ignindex.where(summoner_id: x.summoner_id).where(summoner_validated: true).each do |ign|
              ign.update(summoner_validated: false)
              Rails.logger.info "User #{ign.user_id} is no longer valid, duplicate summoner name"
            end
          end
          x.update(summoner_validated: true)
          x.update(validation_timer: nil)
          x.update(validation_string: nil)
          Rails.logger.info "#{x.summoner_name} validated"
        else
          Rails.logger.info "#{x.summoner_name} not validated"
        end

      end
    end

    Status.where("value > ?", 0).each do |x|
      x.update(value: 10860 - (Time.now.to_i - x.created_at.to_i))
      Rails.logger.info "start for #{x.summoner_id}"
        if Time.now.to_i - x.created_at.to_i > 10860
          x.update(value: 0)
          x.update(content: "Time ran out!")
        else
          sleep 0.8
          url = "https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/#{x.summoner_id}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
          Rails.logger.info "api call for #{x.summoner_id}"
          api_call_count += 1 
          remote4_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
          games_hash = JSON.parse(remote4_data)
          valid_games = []
          i = 0
          games_hash["matches"].each do |match|
            if match["queueType"] == "RANKED_SOLO_5x5" && (match["matchCreation"] - match["matchDuration"]) >= Status.last.created_at.to_i*1000
              valid_games << i
              i = i + 1
            else
              i = i + 1
            end
          end
        if x.kind == 1
          Rails.logger.info "challenge kind 1 for #{x.summoner_id}"
          if valid_games.count == 0
            x.update(content: "Challenge still running!")
            Rails.logger.info "updated zero games for #{x.summoner_id}" 
          elsif !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
            x.update(content: "You lost the first game! \n First Game: \n Champion: #{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}; #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}")
            x.update(value: 0)
            Rails.logger.info "updated lost first for #{x.summoner_id}"
          elsif !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
            x.update(content: "You won a 1/1 challenge! \n First Game: \n Champion: #{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}; #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}")
            x.update(value: 0)
            Score.find_by_user_id(x.user_id).update(week_1: Score.find_by_user_id(x.user_id).week_1 + x.points)
            Rails.logger.info "won 1/1 for #{x.summoner_id}"            
          else
            x.update(content: "Challenge still running!")
            Rails.logger.info "updated else for #{x.summoner_id}"
          end
        elsif x.kind == 2
          Rails.logger.info "challenge kind 2 for #{x.summoner_id}"
          if valid_games.count == 0
            x.update(content: "Challenge still running!")
            Rails.logger.info "updated zero games for #{x.summoner_id}"
          elsif !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
            x.update(content: "You lost the first game! \n First Game: \n Champion: #{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}; #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}")
            x.update(value: 0)
            Rails.logger.info "updated lost first for #{x.summoner_id}"
          elsif valid_games.count <2 
            x.update(content: "Challenge still running!")
            Rails.logger.info "updated <2 games for #{x.summoner_id}"
          elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"] && !games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]
            x.update(content: "You lose in the second game! \n First Game: \n Champion: #{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}; #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]} \n Second Game: \n Champion: #{Champion.find(games_hash["matches"][valid_games[1]]["participants"][0]["championId"]).champion}; #{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["kills"]} - #{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["deaths"]} - #{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["assists"]}")
            x.update(value: 0)
            Rails.logger.info "updated lost second for #{x.summoner_id}"
          elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"] && games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]
            x.update(content: "You won a 2/2 challenge! \n First Game: \n Champion: #{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}; #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]} - #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]} \n Second Game: \n Champion: #{Champion.find(games_hash["matches"][valid_games[1]]["participants"][0]["championId"]).champion}; #{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["kills"]} - #{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["deaths"]} - #{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["assists"]}")
            x.update(value: 0)
            Score.find_by_user_id(x.user_id).update(week_1: Score.find_by_user_id(x.user_id).week_1 + x.points)
            Rails.logger.info "updated won 2/2 for #{x.summoner_id}"
          else
            x.update(content: "Challenge still running!")
            Rails.logger.info "updated else for #{x.summoner_id}"
          end
        else
          Rails.logger.info "missing challenge kind for #{x.summoner_id}"
        end
      end
    end
    Rails.logger.info "Validation calls = #{val_count} | Challenge calls = #{api_call_count} | #{((val_count + api_call_count)/(Time.now - d)).round(2)}/Second"
    Rails.logger.info "*****Finished cron in #{Time.now - d} seconds!*****"
    Rails.logger.info "-----------------------------------"
  end

  def self.update_value2
    Rails.logger.info "updating..... things...."
  end

end