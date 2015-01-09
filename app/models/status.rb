class Status < ActiveRecord::Base

	belongs_to :user
	
	validates :user_id, presence: true
  validate :dr_who, :on => :create
  validate :one_fox_one_gun, :on => :create

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
            url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/#{x.summoner_name.gsub(' ', '%20')}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
            val_count += 1
              begin
                summoner_data = open(URI.encode(url),{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
                summoner_hash = JSON.parse(summoner_data)
                x.update(summoner_id: summoner_hash["#{x.summoner_name.downcase.gsub(' ', '')}"]["id"])
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
            x.update(mastery_1_name: "#{name}")
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
            if Score.find_by_summoner_id(x.summoner_id).nil?
              Score.create!(:summoner_id => x.summoner_id, :summoner_name => x.summoner_name, :week_5 => 0)
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
        time_holder = 3900
      elsif x.kind == 2
        time_holder = 7200
      else
        time_holder = 10800
      end

      if Time.now.to_i - d > 53
         Rails.logger.info "CRON OVERLOAD! Unable to get matches for #{x.summoner_name}!"
      elsif api_call_count+val_count > 60
        Rails.logger.info "API OVERLOAD! Unable to get matches for #{x.summoner_name}!"
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
                  if match["queueType"] == "RANKED_SOLO_5x5" && (match["matchCreation"] - match["matchDuration"]) >= (x.created_at.to_i - 420)*1000
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
                Score.find_by_user_id(x.user_id).update(week_5: Score.find_by_user_id(x.user_id).week_5 + x.points)
                Score.find_by_summoner_id(x.summoner_id).update(week_5: Score.find_by_summoner_id(x.summoner_id).week_5 + x.points)
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
                  Score.find_by_user_id(x.user_id).update(week_5: Score.find_by_user_id(x.user_id).week_5 + x.points)
                  Score.find_by_summoner_id(x.summoner_id).update(week_5: Score.find_by_summoner_id(x.summoner_id).week_5 + x.points)
                  Rails.logger.info "updated won 2/2 for #{x.summoner_id}"
                else
                  Rails.logger.info "updated else for #{x.summoner_id}"
                end
              else
                Rails.logger.info "missing challenge kind for #{x.summoner_id}"
              end
            elsif x.kind == 3
              Rails.logger.info "challenge kind 3 for #{x.summoner_id}"
              if valid_games.count == 0
                Rails.logger.info "updated zero games for #{x.summoner_id}"
              elsif valid_games.count == 1
                Rails.logger.info "updated 1/3 games for #{x.summoner_id}"
                if x.game_1.empty?
                  x.update(game_1: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"})
                  if !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                    x.update(value: 0)
                    x.update(win_value: 0)
                    Rails.logger.info "updated lost first for #{x.summoner_id}"
                  end
                else
                  puts "game_1 info already saved from previous call"
                end
              elsif valid_games.count == 2
                Rails.logger.info "updated 2/3 games for #{x.summoner_id}"
                if x.game_1.empty?
                  x.update(game_1: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"})
                end
                if games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"] && !games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]
                  x.update(game_2: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[1]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[1]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[1]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["assists"]}"})
                  x.update(value: 0)
                  x.update(win_value: 0)
                  Rails.logger.info "updated lost second out of 2/3 for #{x.summoner_id}"
                elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"] && games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]
                  x.update(game_2: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[1]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[1]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[1]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["assists"]}"})
                  Rails.logger.info "updated won 2/3 for #{x.summoner_id}"
                else
                  Rails.logger.info "updated else for #{x.summoner_id}"
                end
              elsif valid_games.count == 3
                Rails.logger.info "updated 3/3 games for #{x.summoner_id}"
                if x.game_1.empty?
                  x.update(game_1: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"})
                end
                if x.game_2.empty?
                  x.update(game_2: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[1]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[1]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[1]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["assists"]}"})
                end
                if games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"] && games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"] && !games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["winner"]
                  x.update(game_3: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[2]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[2]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[2]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["assists"]}"})
                  x.update(value: 0)
                  x.update(win_value: 0)
                  Rails.logger.info "updated lost third out of 3/3 for #{x.summoner_id}"
                elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"] && games_hash["matches"][valid_games[1]]["participants"][0]["stats"]["winner"] && games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["winner"]
                  x.update(game_3: {:champion_id => "#{Champion.find(games_hash["matches"][valid_games[2]]["participants"][0]["championId"]).champion}", :matchCreation => "#{games_hash["matches"][valid_games[2]]["matchCreation"]}", :win_loss => "#{games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["winner"]}", :matchDuration => "#{games_hash["matches"][valid_games[2]]["matchDuration"]}", :kills => "#{games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["kills"]}", :deaths => "#{games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["deaths"]}", :assists => "#{games_hash["matches"][valid_games[2]]["participants"][0]["stats"]["assists"]}"})
                  x.update(value: 0)
                  x.update(win_value: 2)
                  Score.find_by_user_id(x.user_id).update(week_5: Score.find_by_user_id(x.user_id).week_5 + x.points)
                  Score.find_by_summoner_id(x.summoner_id).update(week_5: Score.find_by_summoner_id(x.summoner_id).week_5 + x.points)
                  Rails.logger.info "updated won 3/3 for #{x.summoner_id}"
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
  bf = []
  while bf.count < 100
    bf << bf.count+1
  end
  puts "outside loop #{bf}!"
end

def dr_who
  w = self.user_id
  if Ignindex.find_by_user_id(w).summoner_validated == true
  else
    errors.add(:you_need, ' a valid summoner name before you can start a challenge!')
  end
end

def one_fox_one_gun
  if Status.all.where("user_id = ?", self.user_id).where(win_value: nil).count >= 1
    errors.add(:you_can, 'only have 1 challenge running at a time!')
  elsif Status.all.where("user_id = ?", self.user_id).where("created_at > ?", Time.now - 22.hours).count >= 5
    errors.add(:you_have, 'reached your challenge limit for the day! The limit refreshes every 22 hours')
  elsif Status.all.where("created_at >= ?", Time.now - 60.seconds).count > 10
    errors.add(:challenge_hamster, ' is overloaded with other challenges! Try back in 60 seconds')
  end
end

def challenge_init
  if self.kind == 1
    self.update(challenge_description: "Win the next game")
    self.update(value: 3900)
    self.update(points: 1)
  elsif self.kind == 2
    self.update(challenge_description: "Win the next 2 games in a row")
    self.update(value: 7200)
    self.update(points: 0)
  elsif self.kind == 3
    self.update(challenge_description: "Win the next 3 games in a row")
    self.update(value: 10800)
    self.update(points: 0)
  elsif self.kind == 4
    self.update(challenge_description: "Win with a random champion")
    self.update(value: 3900)
    self.update(points: 2)
    champ_ids = []
    Champion.all.where.not(champion:nil).sample(60).each {|x| champ_ids << x.id}
    self.update(content: champ_ids.to_s)
  else
    self.update(challenge_description: "Something went wrong! Sorry!")
    self.update(value: 0)
    self.update(points: 0)
  end

  self.update(pause_timer: 0)
  self.update(trigger_timer: 0)
end


def update_champions
p = 420
while p < 422
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

  def self.api_call
    Rails.logger.info "*****STARTING CLOCKWORK*****"
    cron_st = Time.now.to_i
    time_holder = 3900
    times_run = 0
    val_count = 0
    api_call_count = 0 #repeat
    throttle_total = 0

    key_summoner = []
    mass_summoner = ""
    mass_count = 0 
    that_comma = 0
    val_st = Time.now.to_i

    Ignindex.where("validation_timer > ?", 0 ).each do |x|
      if x.validation_timer < (Time.now.to_i - 300)
        Rails.logger.info "#{x.summoner_name} ran out of time"
        Ignindex.find_by_id(x.id).update(validation_timer: nil)
        Ignindex.find_by_id(x.id).update(validation_string: nil)
      else
        Rails.logger.info "#{x.summoner_name} still has #{300 + x.validation_timer - Time.now.to_i} seconds!"
        if x.summoner_id.nil?
          Rails.logger.info "#{x.summoner_name} summoner.id is nill"
          mass_count += 1
          if x.summoner_name_ref != x.summoner_name.downcase.gsub(' ', '')
            x.update(summoner_name_ref: "#{x.summoner_name.downcase.gsub(' ', '')}")
          end
          Rails.logger.info "updating id for #{x.summoner_name}"
          if that_comma == 0
            mass_summoner << "#{x.summoner_name.downcase}"
             that_comma +=1
          else
            mass_summoner << ",#{x.summoner_name.downcase}"
          end
          if mass_count > 0 && mass_count%40 == 0
            Rails.logger.info "Running api call for (#{mass_summoner})"
            url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/#{mass_summoner}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
            puts url
            val_count += 1
            begin
              Rails.logger.info "Running API call successfully for mass_summoner on name"
              summoner_data = open(URI.encode(url),{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
              summoner_hash = JSON.parse(summoner_data)     
              Rails.logger.info "#{summoner_hash}"
                summoner_hash.each_pair do |summoner_hash_key,summoner_hash_value|

                  Ignindex.find_by_summoner_name_ref(summoner_hash_key).update(summoner_id: summoner_hash["#{summoner_hash_key}"]["id"])
                
                    if Score.find_by_summoner_id(summoner_hash["#{x}"]["id"]).nil?
                      Score.create!(:summoner_id => summoner_hash["#{x}"]["id"], :summoner_name => summoner_hash["#{x}"]["name"])
                      Rails.logger.info "scorecard created for #{summoner_hash["#{x}"]["id"]}"
                    else
                      Rails.logger.info "scorecard already exists for #{summoner_hash["#{x}"]["id"]}"
                    end

                end
            rescue Timeout::Error
              Rails.logger.info "URI-TIMEOUT request for mass_summoner on name"
            rescue => e
              Rails.logger.info "uri error request for mass_summoner on name"
            end

            mass_summoner = ""
            that_comma = 0
            times_run += 1

          else
            Rails.logger.info "#{x.summoner_name} queued for mass cycle"
          end
        else
          Rails.logger.info "already have id for #{x.summoner_name}"
        end
      end
    end

    if (mass_count > 40 && mass_count%40 != 0) or (mass_count < 40 && mass_count != 0)
      Rails.logger.info "Remainder count for summoner name to id"
      url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/#{mass_summoner}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
      puts url
      val_count += 1
      begin
        summoner_data = open(URI.encode(url),{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
        summoner_hash = JSON.parse(summoner_data)

        summoner_hash.each_pair do |x,y|
          
          Ignindex.find_by_summoner_name_ref(x).update(summoner_id: summoner_hash["#{x}"]["id"])

            if Score.find_by_summoner_id(summoner_hash["#{x}"]["id"]).nil?
              Score.create!(:summoner_id => summoner_hash["#{x}"]["id"], :summoner_name => summoner_hash["#{x}"]["name"])
              Rails.logger.info "scorecard created for #{summoner_hash["#{x}"]["id"]}"
            else
              Rails.logger.info "scorecard already exists for #{summoner_hash["#{x}"]["id"]}"
            end
        
        end

        Rails.logger.info "time after hash #{Time.now.to_i - val_st} seconds!"
      rescue Timeout::Error
        Rails.logger.info "URI-TIMEOUT request for mass_summoner on name"
      rescue => e
        Rails.logger.info "uri error request for mass_summoner on name"
      end
    else
      Rails.logger.info "ran remainder count didn't run, but sees #{mass_count}"
    end
    Rails.logger.info "completed summoner_name to _id in #{Time.now.to_i - val_st} seconds!"

    mass_count = 0
    mass_summoner = ""
    that_comma = 0

    Ignindex.where("validation_timer > ?", 0 ).where.not(summoner_id: nil).each do |x|
      mass_count += 1
      if that_comma == 0
        mass_summoner << "#{x.summoner_id}"
         that_comma +=1
      else
        mass_summoner << ",#{x.summoner_id}"
      end

      if mass_count > 0 && mass_count%40 == 0
        url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/#{mass_summoner}/masteries?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
        val_count += 1
        begin
          mastery_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
          mastery_hash = JSON.parse(mastery_data)
          
          mastery_hash.each_pair do |key,value|

            Ignindex.find_by_summoner_id(key).update(mastery_1_name: "#{mastery_hash["#{key}"]["pages"][0]["name"]}")
            Rails.logger.info "1st page name: #{mastery_hash["#{key}"]["pages"][0]["name"]}"

            if "#{mastery_hash["#{key}"]["pages"][0]["name"]}" == Ignindex.find_by_summoner_id(key).validation_string
              if Ignindex.where(summoner_id: key).where(summoner_validated: true).count > 1
                Ignindex.where(summoner_id: key).where(summoner_validated: true).each do |ign|
                  ign.update(summoner_validated: false)
                  Rails.logger.info "User #{ign.user_id} is no longer valid, duplicate summoner name"
                end
              end
              Ignindex.find_by_summoner_id(key).update(summoner_validated: true)
              Ignindex.find_by_summoner_id(key).update(validation_timer: nil)
              Ignindex.find_by_summoner_id(key).update(validation_string: nil)
              Rails.logger.info "key validated"

            else
              Rails.logger.info "key not validated"
            end
          end
          that_comma = 0
          mass_summoner = ""
        rescue Timeout::Error
          Rails.logger.info "URI-TIMEOUT request on masteries"
          that_comma = 0
          mass_summoner = ""
        rescue => e
          Rails.logger.info "uri error request on masteries"
          that_comma = 0
          mass_summoner = ""
        end
      end 
    end #part 2

    #remainder api call
    if (mass_count > 40 && mass_count%40 != 0) or (mass_count < 40 && mass_count != 0)
      Rails.logger.info "ran remainder count for masteries"

      Rails.logger.info "time before ign call #{Time.now.to_i - val_st} seconds!"
      url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/#{mass_summoner}/masteries?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
      val_count += 1
      begin
        mastery_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
        mastery_hash = JSON.parse(mastery_data)
        mastery_hash.each_pair do |key,value|

          Ignindex.find_by_summoner_id(key).update(mastery_1_name: "#{mastery_hash["#{key}"]["pages"][0]["name"]}")
          Rails.logger.info "1st page name: #{mastery_hash["#{key}"]["pages"][0]["name"]}"

          if "#{mastery_hash["#{key}"]["pages"][0]["name"]}" == Ignindex.find_by_summoner_id(key).validation_string
            if Ignindex.where(summoner_id: key).where(summoner_validated: true).count > 1
              Ignindex.where(summoner_id: key).where(summoner_validated: true).each do |ign|
                ign.update(summoner_validated: false)
                Rails.logger.info "User #{ign.user_id} is no longer valid, duplicate summoner name"
              end
            end
            Ignindex.find_by_summoner_id(key).update(summoner_validated: true)
            Ignindex.find_by_summoner_id(key).update(validation_timer: nil)
            Ignindex.find_by_summoner_id(key).update(validation_string: nil)
            Rails.logger.info "key validated"
          else

            Rails.logger.info "key not validated"
          end
        end
        that_comma = 0
        mass_summoner = ""
      rescue Timeout::Error
        Rails.logger.info "URI-TIMEOUT request on masteries"
        that_comma = 0
        mass_summoner = ""
      rescue => e
        Rails.logger.info "uri error request on masteries"
        that_comma = 0
        mass_summoner = ""
      end
    else
    Rails.logger.info "ran remainder count didn't run, but sees #{mass_count} for masteries"
    end
    Rails.logger.info "completed validations in #{Time.now.to_i - cron_st} seconds!"


    #general instance veriables

    #status specific instance variables
    pause_timer_bench = 360
    trigger_timer_bench = 300
    api_call_count = 0 #tracker of total API calls
    time_holder = 3900 #total time allocation for status
    hydra_food = [] #queued status objects for hydra call
    times_run = 0 #counter for times hydra ran
    status_st = Time.now.to_i #required for throttle + logger
    mass_count = 0 #count of status objects queued
    total_count = 0
    timeout_count = 0
    api_overload_count = 0

    Status.where(win_value: nil).order(created_at: :desc).each do |status| #=> all active statuses
      total_count += 1
      if Time.now.to_i - cron_st > 55
        Rails.logger.info "CRON TIMEOUT OVERLOAD! Unable to get matches for #{status.summoner_name}!"
        timeout_count += 1
      elsif mass_count > 40
        Rails.logger.info "CRON API OVERLOAD! Unable to get matches for #{status.summoner_name}!"
        api_overload_count += 1
      else

        
        if status.pause_timer.nil?
          status.update(pause_timer: 0)
        end

        if status.trigger_timer.nil?
          status.update(trigger_timer: 0)
        end

        if (status.pause_timer > 0) && (status.pause_timer < (Time.now.to_i - pause_timer_bench)) #=> auto-end pause timers
          Rails.logger.info "Status: #{status.summoner_name} is auto-unpaused"
          status.update(value: (status.value + Time.now.to_i - status.pause_timer))
          status.update(pause_timer: 0)
        elsif status.pause_timer > 0 # status is paused, do nothing
          Rails.logger.info "Status: #{status.summoner_name} is paused"
        elsif Time.now.to_i - status.created_at.to_i - status.value > 0 #=> terminate timeouts
          Rails.logger.info "Status: #{status.summoner_name} has timed out"
          status.update(win_value: 1)
        elsif ((Time.now.to_i - status.created_at.to_i - status.value) > -119) or (status.trigger_timer > (Time.now.to_i - trigger_timer_bench)) 

          mass_count += 1
          hydra_food << status
          Rails.logger.info "add to hydra for #{status.summoner_name} on #{times_run}/#{mass_count}"
          if mass_count > 0 && mass_count%8 == 0 

          times_run += 1
          api_call_count += hydra_food.count
          Rails.logger.info "***hydra_food/times_run at start: #{hydra_food.count}/#{times_run}"

          hydra = Typhoeus::Hydra.new(:max_concurrency => 200)
          hst = Time.now
          hydra_food.each do |food|
            url = "https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/#{food.summoner_id}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
            request = Typhoeus::Request.new(url, :timeout => 3)
            hydra.queue(request)
            request.on_complete do |response|
              if response.success?
                
                games_hash = JSON.parse(response.body)

                if games_hash["matches"].nil? #if API returns nil data
                  Rails.logger.info "games_hash matches are nil for someone!"
                else
                 
                  key_summoner = []
                  hydra_food.each do |temp_status_looper|
                    if temp_status_looper.summoner_id == response.effective_url[52...(response.effective_url.length - 45)].to_i
                      puts "#{temp_status_looper.summoner_id} matched with url #{response.effective_url[52...(response.effective_url.length - 45)]}"
                      key_summoner << temp_status_looper
                    end
                  end

                  if key_summoner == []
                    Rails.logger.info "RIOT API ERROR: returning incorrect summonerid/name"
                  else 
                    Rails.logger.info "****key summoner_id = #{key_summoner[0].summoner_id}, matched from #{games_hash["matches"][0]["participantIdentities"][0]["player"]["summonerId"]}"

                    valid_games = []
                    i = 0
                    games_hash["matches"].each do |match|
                      if match["queueType"] == "RANKED_SOLO_5x5" && (match["matchCreation"] - match["matchDuration"]) >= (key_summoner[0].created_at.to_i - 420)*1000
                        valid_games << i
                        i = i + 1
                      else
                        i = i + 1
                      end
                    end

                    if valid_games[0].nil?
                      Rails.logger.info "nil valid_games for #{key_summoner[0].summoner_id}"
                    else
                      Rails.logger.info "valid_games for #{key_summoner[0].summoner_id}: #{valid_games}"
                      if key_summoner[0].kind == 1
                        Rails.logger.info "challenge kind 1 for #{key_summoner[0].summoner_id}"
                        if !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          Status.find(key_summoner[0].id).update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          Status.find(key_summoner[0].id).update(win_value: 0)
                          Rails.logger.info "updated lost first for #{key_summoner[0].summoner_id}"
                        elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                           Status.find(key_summoner[0].id).update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          Status.find(key_summoner[0].id).update(win_value: 2)
                          Score.find_by_user_id(key_summoner[0].user_id).update(week_5: Score.find_by_user_id(key_summoner[0].user_id).week_5 + key_summoner[0].points)
                          Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_5: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_5 + key_summoner[0].points)
                          Rails.logger.info "won 1/1 for #{key_summoner[0].summoner_id}"            
                        else
                          Rails.logger.info "updated else for #{key_summoner[0].summoner_id}"
                        end
                      elsif key_summoner[0].kind == 4
                        Rails.logger.info "challenge kind 4 for #{key_summoner[0].summoner_id}"
                        if !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          Status.find(key_summoner[0].id).update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          Status.find(key_summoner[0].id).update(win_value: 0)
                          Rails.logger.info "updated lost first for #{key_summoner[0].summoner_id}"
                        elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          if key_summoner[0].content[1...key_summoner[0].content.length-1].split.map(&:to_i).include?(games_hash["matches"][valid_games[0]]["participants"][0]["championId"])
                            Status.find(key_summoner[0].id).update(game_1: {
                              :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                              :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                              :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                              :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                              :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                              :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                              :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                              })
                            Status.find(key_summoner[0].id).update(win_value: 2)
                            Score.find_by_user_id(key_summoner[0].user_id).update(week_5: Score.find_by_user_id(key_summoner[0].user_id).week_5 + key_summoner[0].points)
                            Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_5: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_5 + key_summoner[0].points)
                            Rails.logger.info "won 1/1 for #{key_summoner[0].summoner_id}"    
                          else
                            Status.find(key_summoner[0].id).update(game_1: {
                              :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                              :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                              :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                              :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                              :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                              :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                              :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                              })
                            Status.find(key_summoner[0].id).update(win_value: 0)
                            Rails.logger.info "updated win with wrong champion for #{key_summoner[0].summoner_id}"
                          end
                        else
                          Rails.logger.info "updated else for #{key_summoner[0].summoner_id}"
                        end                        
                      else
                        Rails.logger.info "wrong kind for #{key_summoner[0].summoner_id}"
                      end
                    end
                    Rails.logger.info "Ran cycle num: #{times_run} for total mass of: #{mass_count}"
                  end

                end

              elsif response.timed_out?
                Rails.logger.info "Hydra timeout on cycle num: #{times_run} for mass of: #{mass_count}"
              elsif response.code == 0
                Rails.logger.info "Hydra issue (#{response.return_message}) on cycle num: #{times_run} for mass of: #{mass_count}"
              else
                Rails.logger.info "Hydra HTTP failed (#{response.code.to_s}) on cycle num: #{times_run} for mass of: #{mass_count}"
              end

            end
          end
          hydra.run
          het = Time.now
          puts "\n" + (het - hst).to_s() + " seconds for hydra"

          ct = Time.now.to_i
          hydra_food = []
          if (ct-cron_st) < times_run*11
            Rails.logger.info "Throttle for #{times_run*11-(ct-cron_st)} seconds"
            throttle_total += times_run*11-(ct-cron_st)
            sleep times_run*11-(ct-cron_st)
          end
        else

          end

        else  #=> running challenges not being checked go here
          #Rails.logger.info "Background: #{status.summoner_name} is active but in background"
        end
      end
    end

      if (mass_count > 8 && mass_count%8 != 0) or (mass_count < 8 and mass_count !=0)
        times_run += 1
        api_call_count += hydra_food.count
        Rails.logger.info "***hydra_food at start: #{hydra_food.count}"

        Rails.logger.info "ran hydra times_run is about to run for: #{times_run}"
        hydra = Typhoeus::Hydra.new(:max_concurrency => 200)
        hst = Time.now
        hydra_food.each do |food|
          url = "https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/#{food.summoner_id}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
          request = Typhoeus::Request.new(url, :timeout => 3)
          hydra.queue(request)
          request.on_complete do |response|
            if response.success?
              
              games_hash = JSON.parse(response.body)

              if games_hash["matches"].nil? #if API returns nil data
                Rails.logger.info "games_hash matches are nil for someone!"
              else

                key_summoner = []
                hydra_food.each do |temp_status_looper|
                  if temp_status_looper.summoner_id == response.effective_url[52...(response.effective_url.length - 45)].to_i
                    puts "#{temp_status_looper.summoner_id} matched with  #{response.effective_url[52...(response.effective_url.length - 45)]}"
                    key_summoner << temp_status_looper
                  end
                end

                if key_summoner == []
                  Rails.logger.info "RIOT API ERROR: returning incorrect summonerid/name"
                else 
                  Rails.logger.info "****key summoner_id = #{key_summoner[0].summoner_id}, matched from #{games_hash["matches"][0]["participantIdentities"][0]["player"]["summonerId"]}"

                  valid_games = []
                  i = 0
                  games_hash["matches"].each do |match|
                    if match["queueType"] == "RANKED_SOLO_5x5" && (match["matchCreation"] - match["matchDuration"]) >= (key_summoner[0].created_at.to_i - 420)*1000
                      valid_games << i
                      i = i + 1
                    else
                      i = i + 1
                    end
                  end

                  if valid_games[0].nil?
                    Rails.logger.info "nil valid_games for #{key_summoner[0].summoner_id}"
                  else
                    Rails.logger.info "valid_games for #{key_summoner[0].summoner_id}: #{valid_games}"
                    Rails.logger.info "win status: #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}"
                    
                    if key_summoner[0].kind == 1
                      Rails.logger.info "challenge kind 1 for #{key_summoner[0].summoner_id}"
                     if !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                        Status.find(key_summoner[0].id).update(game_1: {
                          :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                          :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                          :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                          :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                          :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                          :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                          :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                          })
                        Status.find(key_summoner[0].id).update(win_value: 0)
                        Rails.logger.info "updated lost first for #{key_summoner[0].summoner_id}"
                      elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                        if key_summoner[0].content[1...key_summoner[0].content.length-1].split.map(&:to_i).include?(games_hash["matches"][valid_games[0]]["participants"][0]["championId"])
                          Status.find(key_summoner[0].id).update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          Status.find(key_summoner[0].id).update(win_value: 2)
                          Score.find_by_user_id(key_summoner[0].user_id).update(week_5: Score.find_by_user_id(key_summoner[0].user_id).week_5 + key_summoner[0].points)
                          Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_5: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_5 + key_summoner[0].points)
                          Rails.logger.info "won 1/1 for #{key_summoner[0].summoner_id}"    
                        else
                          Status.find(key_summoner[0].id).update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          Status.find(key_summoner[0].id).update(win_value: 0)
                          Rails.logger.info "updated win with wrong champion for #{key_summoner[0].summoner_id}"
                        end
                      else
                        Rails.logger.info "updated else for #{key_summoner[0].summoner_id}"
                      end     
                      elsif key_summoner[0].kind == 4
                        Rails.logger.info "challenge kind 4 for #{key_summoner[0].summoner_id}"
                        if !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          Status.find(key_summoner[0].id).update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          Status.find(key_summoner[0].id).update(win_value: 0)
                          Rails.logger.info "updated lost first for #{key_summoner[0].summoner_id}"
                        elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          if key_summoner[0].content[1...key_summoner[0].content.length-1].split.map(&:to_i).include?(games_hash["matches"][valid_games[0]]["participants"][0]["championId"])
                            Status.find(key_summoner[0].id).update(game_1: {
                              :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                              :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                              :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                              :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                              :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                              :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                              :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                              })
                            Status.find(key_summoner[0].id).update(win_value: 2)
                            Score.find_by_user_id(key_summoner[0].user_id).update(week_5: Score.find_by_user_id(key_summoner[0].user_id).week_5 + key_summoner[0].points)
                            Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_5: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_5 + key_summoner[0].points)
                            Rails.logger.info "won 1/1 for #{key_summoner[0].summoner_id}"    
                          else
                            Status.find(key_summoner[0].id).update(game_1: {
                              :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                              :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                              :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                              :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                              :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                              :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                              :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                              })
                            Status.find(key_summoner[0].id).update(win_value: 0)
                            Rails.logger.info "updated win with wrong champion for #{key_summoner[0].summoner_id}"
                          end
                        else
                          Rails.logger.info "updated else for #{key_summoner[0].summoner_id}"
                        end                       
                    else
                      Rails.logger.info "wrong kind for #{key_summoner[0].summoner_id}"
                    end
                  end
                  Rails.logger.info "Ran cycle num: #{times_run} for total mass of: #{mass_count}"
                end

              end

            elsif response.timed_out?
              Rails.logger.info "Hydra timeout on cycle num: #{times_run} for mass of: #{mass_count}"
            elsif response.code == 0
              Rails.logger.info "Hydra issue (#{response.return_message}) on cycle num: #{times_run} for mass of: #{mass_count}"
            else
              Rails.logger.info "Hydra HTTP failed (#{response.code.to_s}) on cycle num: #{times_run} for mass of: #{mass_count}"
            end

          end
        end
        hydra.run
        het = Time.now
        puts "\n" + (het - hst).to_s() + " seconds for hydra"

        ct = Time.now.to_i
        if (ct-cron_st) < times_run*11
          Rails.logger.info "Throttle for #{times_run*11-(ct-cron_st)} seconds"
          throttle_total += times_run*11-(ct-cron_st)
          sleep times_run*11-(ct-cron_st)
        end
      else
      end

    #end status remainder
    Rails.logger.info "completed challenges in #{Time.now.to_i - status_st} seconds!"
    Rails.logger.info "#{Time.now.to_i} | Cron Duration: #{Time.now.to_i - cron_st} | Throttle: #{throttle_total} | API calls: #{val_count + api_call_count} | Total challenges: #{total_count} | API/second: #{(val_count + api_call_count)/(Time.now.to_i - cron_st).round(2)}/second | max @ #{(val_count + api_call_count*1.00)/(Time.now.to_i - cron_st - throttle_total)}/second | Timeouts: #{timeout_count} | Overloads #{api_overload_count}"
    #puts "#{Time.now.to_i} | Cron Duration: #{Time.now.to_i - cron_st} | Throttle: #{throttle_total} | API calls: #{val_count + api_call_count} | Total challenges: #{total_count} | API/second: #{(val_count + api_call_count)/(Time.now.to_i - cron_st).round(2)}/second | max @ #{(val_count + api_call_count*1.00)/(Time.now.to_i - cron_st - throttle_total)}/second | Timeouts: #{timeout_count} | Overloads #{api_overload_count}"

  end #end of api_call_status



end