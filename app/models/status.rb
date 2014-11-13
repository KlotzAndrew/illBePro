class Status < ActiveRecord::Base

	belongs_to :user
	
	validates :user_id, presence: true
  validate :one_fox_one_gun, on: :create

  after_create :challenge_init

  serialize :game_1, Hash
  serialize :game_2, Hash
  serialize :game_3, Hash
  serialize :game_4, Hash
  serialize :game_5, Hash

  def self.update_value
    Rails.logger.info "*****Started cron at #{Time.now}*****"
    d = Time.now.to_i
    api_call_count = 0
    val_count = 0
    Ignindex.where("validation_timer > ?", 0 ).each do |x|
      if Time.now.to_i - d > 55
         Rails.logger.info "CRON OVERLOAD! Unable to validate #{x.summoner_name}!"
      elsif api_call_count+val_count > 60
        Rails.logger.info "API OVERLOAD! Unable to validate #{x.summoner_name}!"
      else
        if x.validation_timer < (Time.now.to_i - 300)
          x.update(validation_timer: nil)
          x.update(validation_string: nil)
          Rails.logger.info "#{x.id} ran out of time"
        else
          Rails.logger.info "#{x.summoner_name} still has #{300 + x.validation_timer - Time.now.to_i} seconds!"
          if x.summoner_id.nil?
            Rails.logger.info "update id for #{x.summoner_name}"
            g = Time.now.to_i
            if (api_call_count + val_count)*(1/0.80) > g-d
              puts "Throttle for #{(api_call_count + val_count)*(1/0.80) + d - g}"
              sleep (api_call_count + val_count)*(1/0.80) + d - g
            end
            url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/#{x.summoner_name}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
            val_count += 1
              begin
                summoner_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
                summoner_hash = JSON.parse(summoner_data)
                x.update(summoner_id: summoner_hash["#{x.summoner_name.downcase}"]["id"])
              rescue Timeout::Error
                Rails.logger.info "URI-TIMEOUT request for #{x.summoner_name} on name"
              rescue => e
                Rails.logger.info "uri error request for #{x.summoner_name} on name"
              end
          else
            Rails.logger.info "no update id for #{x.summoner_name}"
          end

        g = Time.now.to_i
        if (api_call_count + val_count)*(1/0.80) > g-d
          puts "Throttle for #{(api_call_count + val_count)*(1/0.80) + d - g}"
          sleep (api_call_count + val_count)*(1/0.80) + d - g
        end
        url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/#{x.summoner_id}/masteries?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
        val_count += 1
          begin
            mastery_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
            mastery_hash = JSON.parse(mastery_data)
            name = mastery_hash["#{x.summoner_id}"]["pages"][0]["name"]
            Rails.logger.info "1st page name: #{name}; should be: #{x.validation_string}"
          rescue Timeout::Error
            Rails.logger.info "URI-TIMEOUT request for #{x.summoner_name} on masteries"
          rescue => e
            Rails.logger.info "uri error request for #{x.summoner_name} on masteries"
          end


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
            if !Score.where("summoner_id = ?", x.summoner_id).nil?
              Score.create!(:summoner_id => x.summoner_id, :summoner_name => x.summoner_name, :week_1 => 0)
              Rails.logger.info "scorecard created for #{x.summoner_name}"
            else
              Rails.logger.info "scorecard already exists for #{x.summoner_name}"
            end
          else
            Rails.logger.info "#{x.summoner_name} not validated"
          end
        end
      end
    end

    Status.where("value > ?", 0).each do |x|
      if x.kind == 1
        time_holder = 5400
      else
        time_holder = 7200
      end
      if Time.now.to_i - d > 53
         Rails.logger.info "CRON OVERLOAD! Unable to validate #{x.summoner_name}!"
      elsif api_call_count+val_count > 60
        Rails.logger.info "API OVERLOAD! Unable to update challenges for #{x.summoner_name}!"
      else
        x.update(value: time_holder - (Time.now.to_i - x.created_at.to_i))
        Rails.logger.info "start for #{x.summoner_id}"
          if Time.now.to_i - x.created_at.to_i > time_holder
            x.update(value: 0)
            x.update(win_value: 1)
          else
            g = Time.now.to_i
            if (api_call_count + val_count)*(1/0.80) > g-d
              puts "Throttle for #{(api_call_count + val_count)*(1/0.80) + d - g}"
              sleep (api_call_count + val_count)*(1/0.80) + d - g
            end
            url = "https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/#{x.summoner_id}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
            Rails.logger.info "api call for #{x.summoner_id}"
            api_call_count += 1 
              begin
                remote4_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>2}).read
                games_hash = JSON.parse(remote4_data)
                valid_games = []
                i = 0
                games_hash["matches"].each do |match|
                  if match["queueType"] == "RANKED_SOLO_5x5" && (match["matchCreation"] - match["matchDuration"]) >= (x.created_at.to_i - 180)*1000
                    valid_games << i
                    i = i + 1
                  else
                    i = i + 1
                  end
                end
              rescue Timeout::Error
                 Rails.logger.info "URI-TIMEOUT request for #{x.summoner_name} on stats"
              rescue => e
                Rails.logger.info "uri error request for #{x.summoner_name} on stats"
              end
          if valid_games.nil?
            Rails.logger.info "nil valid_games for #{x.summoner_id}"
          else
            if x.kind == 1
              Rails.logger.info "challenge kind 1 for #{x.summoner_id}"
              if valid_games.count == 0               
                Rails.logger.info "updated zero games for #{x.summoner_id}" 
              elsif !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                x.update(game_1: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"})
                x.update(value: 0)
                x.update(win_value: 0)
                Rails.logger.info "updated lost first for #{x.summoner_id}"
              elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                 x.update(game_1: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"})
                x.update(value: 0)
                x.update(win_value: 2)
                Score.find_by_user_id(x.user_id).update(week_1: Score.find_by_user_id(x.user_id).week_1 + x.points)
                Score.find_by_summoner_id(x.summoner_id).update(week_1: Score.find_by_summoner_id(x.summoner_id).week_1 + x.points)
                Rails.logger.info "won 1/1 for #{x.summoner_id}"            
              else
                Rails.logger.info "updated else for #{x.summoner_id}"
              end
            elsif x.kind == 2
              Rails.logger.info "challenge kind 2 for #{x.summoner_id}"
              if valid_games.count == 0
                Rails.logger.info "updated zero games for #{x.summoner_id}"
              elsif valid_games.count == 1
                Rails.logger.info "updated 1/2 games for #{x.summoner_id}"
                if x.game_1.empty?
                  x.update(game_1: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"})
                  if !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                    x.update(value: 0)
                    x.update(win_value: 0)
                    Rails.logger.info "updated lost first for #{x.summoner_id}"
                  end
                else
                  puts "game_1 info alreayd saved from previous call"
                end
              elsif valid_games.count == 2
                Rails.logger.info "updated 2/2 games for #{x.summoner_id}"
                if x.game_1.empty?
                  x.update(game_1: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"})
                end
                if games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"] && !games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]
                  x.update(game_2: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[1]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[1]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[1]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["assists"]}"})
                  x.update(value: 0)
                  x.update(win_value: 0)
                  Rails.logger.info "updated lost second out of 2/2 for #{x.summoner_id}"
                elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"] && games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]
                  x.update(game_2: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[1]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[1]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[1]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["assists"]}"})
                  x.update(value: 0)
                  x.update(win_value: 2)
                  Score.find_by_user_id(x.user_id).update(week_1: Score.find_by_user_id(x.user_id).week_1 + x.points)
                  Score.find_by_summoner_id(x.summoner_id).update(week_1: Score.find_by_summoner_id(x.summoner_id).week_1 + x.points)
                  Rails.logger.info "updated won 2/2 for #{x.summoner_id}"
                else
                  Rails.logger.info "updated else for #{x.summoner_id}"
                end
              else
                Rails.logger.info "missing challenge kind for #{x.summoner_id}"
              end
            end
          end
        end
      end
    end
    Rails.logger.info "Validation calls = #{val_count} | Challenge calls = #{api_call_count} | #{((val_count + api_call_count*1.00)/(Time.now.to_i - d)).round(2)}/Second"
    Rails.logger.info "*****Finished cron in #{Time.now.to_i - d*1.00} seconds!*****"
    Rails.logger.info "-----------------------------------"
  end

def self.update_value2
  Rails.logger.info "updating..... things...."
end

def one_fox_one_gun
  if Status.all.where("user_id = ?", self.user_id).where("value > ?", 0).count >= 1
    errors.add(:you_can, 'only have 1 challenge running at a time!')
  elsif Status.where("value > ?", 0).count >= 40
    errors.add(:challenge_hampster, ' is overloaded with other challenges! Try back in a few minutes')
  end
end

def challenge_init
  if self.kind == 1
    self.update(challenge_description: "Win your next game!")
    self.update(value: 5400)
    self.update(points: 1)
  elsif self.kind == 2
    self.update(challenge_description: "Win your next 2 games in a row!")
    self.update(value: 7200)
    self.update(points: 3)
  else
    self.update(challenge_description: "Something went wrong! Sorry!")
    self.update(value: 0)
    self.update(points: 0)
  end
end


def update_champions
p = 1
while p < 415
Champion.create(:id => p)
begin
url = "https://na.api.pvp.net/api/lol/static-data/na/v1.2/champion/#{p}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
remote5_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read
champion_hash = JSON.parse(remote5_data)
Champion.find(p).update(champion: "#{champion_hash["key"]}")
puts champion_hash["key"]
p += 1
rescue OpenURI::HTTPError => ex
puts "KANYE for #{p}"
p += 1
end
end
end


end