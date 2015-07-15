class Status < ActiveRecord::Base

	# belongs_to :user
	
	# validates :user_id, presence: true
  validate :dr_who, :on => :create
  validate :one_fox_one_gun, :on => :create
  belongs_to :ignindex

  after_create :challenge_init

  serialize :game_1, Hash
  serialize :game_2, Hash
  serialize :game_3, Hash
  serialize :game_4, Hash
  serialize :game_5, Hash


def dr_who #this makes sure summoner is valid + region is entered
  w = Ignindex.find(self.ignindex_id)
  if w.summoner_validated != true
    errors.add(:you_need, ' a valid summoner name before you can start a challenge!')
  elsif w.region_id.nil?
    errors.add(:you_need, ' to select a prize zone to start a challenge')
  end
end

def one_fox_one_gun #this is 1 game/user + concurrent requests/API
  if Status.all.where("ignindex_id = ?", self.ignindex_id).where(win_value: nil).count > 1
    errors.add(:you_can, 'only have 1 challenge running at a time!')
  #elsif Status.all.where("user_id = ?", self.user_id).where("created_at > ?", Time.now - 22.hours).count >= 5
    #errors.add(:you_have, 'reached your challenge limit for the day! The limit refreshes every 22 hours')
  elsif Status.all.where("created_at >= ?", Time.now - 60.seconds).count > 20
    errors.add(:start_queue, ' is full! Try back in 60 seconds')
  else
  end
end

def challenge_init

  #build baseline for kind 5 (this can be refractored)
  proc = rand(1..100)
  self.update(
    :value => 5400,
    :points => 0,
    :proc_value => proc,
    :kind => 5,
    :challenge_description => "Play a game to increase the chance your next challenge will be prized",
    :pause_timer => 0,
    :trigger_timer => 0,
    :pause_timer => 0,
    :trigger_time => 0)
end


  def self.api_call
    Rails.logger.info "*****STARTING CLOCKWORK*****"
    Staticpage.find(1).update(
      :league_api_ping => Time.now.to_i)
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
      if x.validation_timer < (Time.now.to_i - 600)
        Rails.logger.info "#{x.summoner_name} ran out of time"
        Ignindex.find_by_id(x.id).update(validation_timer: nil)
        Ignindex.find_by_id(x.id).update(validation_string: nil)
      else
        Rails.logger.info "#{cron_st}: #{x.summoner_name} still has #{600 + x.validation_timer - Time.now.to_i} seconds!"
        if x.summoner_id.nil?
          Rails.logger.info "#{cron_st}: #{x.summoner_name} summoner.id is nill"
          mass_count += 1
          if x.summoner_name_ref != x.summoner_name.mb_chars.downcase.gsub(' ', '').to_s
            x.update(summoner_name_ref: "#{x.summoner_name.mb_chars.downcase.gsub(' ', '').to_s}")
          end
          Rails.logger.info "#{cron_st}: updating id for #{x.summoner_name}"
          if that_comma == 0
            mass_summoner << "#{x.summoner_name.downcase}"
             that_comma +=1
          else
            mass_summoner << ",#{x.summoner_name.downcase}"
          end
          if mass_count > 0 && mass_count%40 == 0
            Rails.logger.info "#{cron_st}: Running api call for (#{mass_summoner})"
            url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/#{mass_summoner}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
            puts url
            val_count += 1
            begin
              Rails.logger.info "#{cron_st}: #{cron_st}: Running API call successfully for mass_summoner on name"
              summoner_data = open(URI.encode(url),{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
              summoner_hash = JSON.parse(summoner_data)     
              Rails.logger.info "#{cron_st}: #{summoner_hash}"
                summoner_hash.each_pair do |summoner_hash_key,summoner_hash_value|

                  Ignindex.where("summoner_name_ref = ?", summoner_hash_key).first.update(summoner_id: summoner_hash["#{summoner_hash_key}"]["id"])
                
                    if Score.find_by_summoner_id(summoner_hash["#{x}"]["id"]).nil?
                      Score.create!(:summoner_id => summoner_hash["#{x}"]["id"], :summoner_name => summoner_hash["#{x}"]["name"])
                      Rails.logger.info "#{cron_st}: scorecard created for #{summoner_hash["#{x}"]["id"]}"
                    else
                      Rails.logger.info "#{cron_st}: scorecard already exists for #{summoner_hash["#{x}"]["id"]}"
                    end

                end
            rescue Timeout::Error
              Rails.logger.info "#{cron_st}: URI-TIMEOUT request for mass_summoner on name"
            rescue => e
              Rails.logger.info "#{cron_st}: uri error request for mass_summoner on name"
            end

            mass_summoner = ""
            that_comma = 0
            times_run += 1

          else
            Rails.logger.info "#{cron_st}: #{x.summoner_name} queued for mass cycle"
          end
        else
          Rails.logger.info "#{cron_st}: already have id for #{x.summoner_name}"
        end
      end
    end

    if (mass_count > 40 && mass_count%40 != 0) or (mass_count < 40 && mass_count != 0)
      Rails.logger.info "#{cron_st}: Remainder count for summoner name to id"
      url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/#{mass_summoner}?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
      puts url
      val_count += 1
      begin
        summoner_data = open(URI.encode(url),{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
        summoner_hash = JSON.parse(summoner_data)
          Rails.logger.info "#{cron_st}: summoner_hash: #{summoner_hash}"
        summoner_hash.each_pair do |x,y|

          Rails.logger.info "#{cron_st}: scorecard created for #{summoner_hash["#{x}"]["id"]}"

          Rails.logger.info "#{cron_st}: find by: #{x}, update: #{summoner_hash["#{x}"]["id"]}"

          Ignindex.where("summoner_name_ref = ?", x).first.update(summoner_id: summoner_hash["#{x}"]["id"])

            if Score.find_by_summoner_id(summoner_hash["#{x}"]["id"]).nil?
              Score.create!(:summoner_id => summoner_hash["#{x}"]["id"], :summoner_name => summoner_hash["#{x}"]["name"])
              Rails.logger.info "#{cron_st}: scorecard created for #{summoner_hash["#{x}"]["id"]}"
            else
              Rails.logger.info "#{cron_st}: scorecard already exists for #{summoner_hash["#{x}"]["id"]}"
            end
        
        end

        Rails.logger.info "#{cron_st}: time after hash #{Time.now.to_i - val_st} seconds!"
      rescue Timeout::Error
        Rails.logger.info "#{cron_st}: URI-TIMEOUT request for mass_summoner on name"
      rescue => e
        Rails.logger.info "#{cron_st}: uri error request for mass_summoner on name"
      end
    else
      Rails.logger.info "#{cron_st}: ran remainder count didn't run, but sees #{mass_count}"
    end
    Rails.logger.info "#{cron_st}: completed summoner_name to _id in #{Time.now.to_i - val_st} seconds!"

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

            ign_for_mastery_hash = Ignindex.where("summoner_id = ?", key).first
            ign_for_mastery_hash.update(mastery_1_name: "#{mastery_hash["#{key}"]["pages"][0]["name"]}")
            Rails.logger.info "#{cron_st}: 1st page name: #{mastery_hash["#{key}"]["pages"][0]["name"]}"
            Rails.logger.info "#{cron_st}: 1st page name should be: #{ign_for_mastery_hash.validation_string}"

            if "#{mastery_hash["#{key}"]["pages"][0]["name"]}" == ign_for_mastery_hash.validation_string
              # if ign_for_mastery_hash.where(summoner_validated: true).count > 1
              #   ign_for_mastery_hash.where(summoner_validated: true).each do |ign|
              #     ign.update(summoner_validated: false)
              #     Rails.logger.info "#{cron_st}: User #{ign.user_id} is no longer valid, duplicate summoner name"
              #   end
              # end

            Rails.logger.info "ign_for_mastery_hash.validation_timer: #{ign_for_mastery_hash.validation_timer}"
            Rails.logger.info "User.find_by_summoner_id(ign_for_mastery_hash.validation_timer).nil?: #{User.find_by_summoner_id(ign_for_mastery_hash.validation_timer).nil?}"
            
            #WIP attach_user
            add_a_user = nil
            user = User.where("summoner_id = ?", ign_for_mastery_hash.validation_timer).first
            if user.nil? #check if any user has vaidator
              Rails.logger.info "#{cron_st}: attach_user nope:}"
            else
              user.update(
                :ignindex_id => ign_for_mastery_hash.id)
              Rails.logger.info "#{cron_st}: attach_user yes:"
              Rails.logger.info "#{cron_st}: ign_for_mastery_hash.id: #{ign_for_mastery_hash.id}"

              add_a_user = user.id
            end

            ign_for_mastery_hash.update(
              :last_validation => ign_for_mastery_hash.validation_timer,
              :summoner_validated => true,
              :validation_timer => nil,
              :validation_string => nil,
              :user_id => add_a_user,
              :region_id => ign_for_mastery_hash.region_id_temp)
            Rails.logger.info "#{cron_st}: key validated"

              # user = User.find(ign_for_mastery_hash.user_id)
              # if user.setup_progress == 0
              #   user.update(setup_progress: 1)
              #   Rails.logger.info "#{cron_st}: user #{ign_for_mastery_hash.id} onload from 0 to 1"
              # else 
              #   Rails.logger.info "#{cron_st}: user #{ign_for_mastery_hash.id} not onloaded"
              # end

            else
              Rails.logger.info "#{cron_st}: key not validated"
            end
          end
          that_comma = 0
          mass_summoner = ""
        rescue Timeout::Error
          Rails.logger.info "#{cron_st}: URI-TIMEOUT request on masteries"
          that_comma = 0
          mass_summoner = ""
        rescue => e
          Rails.logger.info "#{cron_st}: uri error request on masteries 1"
          that_comma = 0
          mass_summoner = ""
        end
      end 
    end #part 2

    #remainder api call
    if (mass_count > 40 && mass_count%40 != 0) or (mass_count < 40 && mass_count != 0)
      Rails.logger.info "#{cron_st}: ran remainder count for masteries"
      
      Rails.logger.info "#{cron_st}: time before ign call #{Time.now.to_i - val_st} seconds!"
      url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/#{mass_summoner}/masteries?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72"
      val_count += 1
      begin
        mastery_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
        mastery_hash = JSON.parse(mastery_data)
        mastery_hash.each_pair do |key,value|

          ign_for_mastery_hash = Ignindex.where("summoner_id = ?", key).first
          ign_for_mastery_hash.update(mastery_1_name: "#{mastery_hash["#{key}"]["pages"][0]["name"]}")
          Rails.logger.info "#{cron_st}: 1st page name: #{mastery_hash["#{key}"]["pages"][0]["name"]}"
          Rails.logger.info "#{cron_st}: 1st page name should be: #{ign_for_mastery_hash.validation_string}"          

          if "#{mastery_hash["#{key}"]["pages"][0]["name"]}" == ign_for_mastery_hash.validation_string
            # if ign_for_mastery_hash.where(summoner_validated: true).count > 1
            #   ign_for_mastery_hash.where(summoner_validated: true).each do |ign|
            #     ign.update(summoner_validated: false)
            #     Rails.logger.info "#{cron_st}: User #{ign.user_id} is no longer valid, duplicate summoner name"
            #   end
            # end

            Rails.logger.info "ign_for_mastery_hash.validation_timer: #{ign_for_mastery_hash.validation_timer}"
            Rails.logger.info "User.find_by_summoner_id(ign_for_mastery_hash.validation_timer).nil?: #{User.find_by_summoner_id(ign_for_mastery_hash.validation_timer).nil?}"
            
            #WIP attach_user
            add_a_user = nil
            user = User.where("summoner_id = ?", ign_for_mastery_hash.validation_timer).first
            if user.nil? #check if any user has vaidator
              Rails.logger.info "#{cron_st}: attach_user nope: "
            else
              user.update(
                :ignindex_id => ign_for_mastery_hash.id)
              Rails.logger.info "#{cron_st}: attach_user yes:"
              Rails.logger.info "#{cron_st}: ign_for_mastery_hash.id: #{ign_for_mastery_hash.id}"

              add_a_user = user.id
            end

            ign_for_mastery_hash.update(
              :last_validation => ign_for_mastery_hash.validation_timer,
              :summoner_validated => true,
              :validation_timer => nil,
              :validation_string => nil,
              :user_id => add_a_user,
              :region_id => ign_for_mastery_hash.region_id_temp)
            Rails.logger.info "#{cron_st}: key validated"

            # user = User.find(ign_for_mastery_hash.user_id)
            # if user.setup_progress == 0
            #   user.update(setup_progress: 1)
            #   Rails.logger.info "#{cron_st}: user #{ign_for_mastery_hash.id} onload from 0 to 1"
            # else 
            #   Rails.logger.info "#{cron_st}: user #{ign_for_mastery_hash.id} not onloaded"
            # end

          else
            Rails.logger.info "#{cron_st}: key not validated"
          end
        end
        that_comma = 0
        mass_summoner = ""
      rescue Timeout::Error
        Rails.logger.info "#{cron_st}: URI-TIMEOUT request on masteries"
        that_comma = 0
        mass_summoner = ""
      rescue => e
        Rails.logger.info "#{cron_st}: uri error request on masteries 2"
        that_comma = 0
        mass_summoner = ""
      end
    else
    Rails.logger.info "#{cron_st}: ran remainder count didn't run, but sees #{mass_count} for masteries"
    end
    Rails.logger.info "#{cron_st}: completed validations in #{Time.now.to_i - cron_st} seconds!"


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
        Rails.logger.info "#{cron_st}: CRON TIMEOUT OVERLOAD! Unable to get matches for #{status.summoner_name}!"
        timeout_count += 1
      elsif mass_count > 40
        Rails.logger.info "#{cron_st}: CRON API OVERLOAD! Unable to get matches for #{status.summoner_name}!"
        api_overload_count += 1
      else

        
        if status.pause_timer.nil?
          status.update(pause_timer: 0)
        end

        if status.trigger_timer.nil?
          status.update(trigger_timer: 0)
        end

        if (status.pause_timer > 0) && (status.pause_timer < (Time.now.to_i - pause_timer_bench)) #=> auto-end pause timers
          Rails.logger.info "#{cron_st}: Status: #{status.summoner_name} is auto-unpaused"
          status.update(value: (status.value + Time.now.to_i - status.pause_timer))
          status.update(pause_timer: 0)
        elsif status.pause_timer > 0 # status is paused, do nothing
          Rails.logger.info "#{cron_st}: Status: #{status.summoner_name} is paused"
        elsif Time.now.to_i - status.created_at.to_i - status.value > 0 #=> terminate timeouts
          Rails.logger.info "#{cron_st}: Status: #{status.summoner_name} has timed out"
          status.update(win_value: 1)
          # if status.kind == 6 #re-open lost prize
          #   Prize.find(status.prize_id).update(
          #     :assignment => 0,
          #     :user_id => nil) 
          # end
        elsif ((Time.now.to_i - status.created_at.to_i - status.value) > -119) or (status.trigger_timer > (Time.now.to_i - trigger_timer_bench)) 

          mass_count += 1
          hydra_food << status
          Rails.logger.info "#{cron_st}: add to hydra for #{status.summoner_name} on #{times_run}/#{mass_count}"
          if mass_count > 0 && mass_count%8 == 0 

          times_run += 1
          api_call_count += hydra_food.count
          Rails.logger.info "#{cron_st}: ***hydra_food/times_run at start: #{hydra_food.count}/#{times_run}"

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
                  Rails.logger.info "#{cron_st}: games_hash matches are nil for someone!"
                else
                 
                  key_summoner = []
                  hydra_food.each do |temp_status_looper|
                    if temp_status_looper.summoner_id == response.effective_url[52...(response.effective_url.length - 45)].to_i
                      puts "#{temp_status_looper.summoner_id} matched with url #{response.effective_url[52...(response.effective_url.length - 45)]}"
                      key_summoner << temp_status_looper
                    end
                  end

                  if key_summoner == []
                    Rails.logger.info "#{cron_st}: RIOT API ERROR: returning incorrect summonerid/name"
                  else 
                    Rails.logger.info "#{cron_st}: ****key summoner_id = #{key_summoner[0].summoner_id}, matched from #{games_hash["matches"][0]["participantIdentities"][0]["player"]["summonerId"]}"

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
                      Rails.logger.info "#{cron_st}: nil valid_games for #{key_summoner[0].summoner_id}"
                    else
                      Rails.logger.info "#{cron_st}: valid_games for #{key_summoner[0].summoner_id}: #{valid_games}"
                      if key_summoner[0].kind == 1
                        Rails.logger.info "#{cron_st}: challenge kind 1 for #{key_summoner[0].summoner_id}"
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
                          Rails.logger.info "#{cron_st}: updated lost first for #{key_summoner[0].summoner_id}"
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
                          Score.find_by_user_id(key_summoner[0].user_id).update(week_6: Score.find_by_user_id(key_summoner[0].user_id).week_6 + key_summoner[0].points)
                          Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_6: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_6 + key_summoner[0].points)
                          Rails.logger.info "#{cron_st}: won 1/1 for #{key_summoner[0].summoner_id}"            
                        else
                          Rails.logger.info "#{cron_st}: updated else for #{key_summoner[0].summoner_id}"
                        end
                      elsif key_summoner[0].kind == 4
                        Rails.logger.info "#{cron_st}: challenge kind 4 for #{key_summoner[0].summoner_id}"
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
                          Rails.logger.info "#{cron_st}: updated lost first for #{key_summoner[0].summoner_id}"
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
                            Score.find_by_user_id(key_summoner[0].user_id).update(week_6: Score.find_by_user_id(key_summoner[0].user_id).week_6 + key_summoner[0].points)
                            Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_6: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_6 + key_summoner[0].points)
                            Rails.logger.info "#{cron_st}: won 1/1 for #{key_summoner[0].summoner_id}"    
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
                            Rails.logger.info "#{cron_st}: updated win with wrong champion for #{key_summoner[0].summoner_id}"
                          end
                        else
                          Rails.logger.info "#{cron_st}: updated else for #{key_summoner[0].summoner_id}"
                        end                        
                      elsif key_summoner[0].kind == 5 || key_summoner[0].kind == 6
                        Rails.logger.info "#{cron_st}: challenge kind #{key_summoner[0].kind} for #{key_summoner[0].summoner_id}"
                        if !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          clock_active_status = Status.find(key_summoner[0].id)
                          clock_active_status.update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          clock_active_status.update(win_value: 0)

                          ign_score = Ignindex.find(key_summoner[0].ignindex_id)
                          curent_ach = Achievement.find(ign_score.active_achievement)
                          if !curent_ach.nil?
                            achievement_play(cron_st, curent_ach, clock_active_status)
                            # experience_gain(cron_st, curent_ach, clock_active_status)
                          end

                          Rails.logger.info "#{cron_st}: updated lost first for #{key_summoner[0].summoner_id}"
                        elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          clock_active_status = Status.find(key_summoner[0].id)
                          clock_active_status.update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          clock_active_status.update(win_value: 2)

                          ign_score = Ignindex.find(key_summoner[0].ignindex_id)

                          proc = rand(1..100)
                          Rails.logger.info "#{cron_st}: proc value is #{proc}"

                          random_prize(cron_st, ign_score, clock_active_status)

                          if key_summoner[0].kind == 6
                            ign_score.update(prize_id: key_summoner[0].prize_id)
                          elsif key_summoner[0].kind == 5
                            # score.update(challenge_points: score.challenge_points + key_summoner[0].points)                                   
                          else
                          end 

                          if !clock_active_status.user_id.nil?
                            user_onload = User.find(clock_active_status.user_id)
                            if user_onload.setup_progress == 0
                              user_onload.update(setup_progress: 1)
                              Rails.logger.info "#{cron_st}: user onload from 0 to 1"
                            else 
                              Rails.logger.info "#{cron_st}: user not onloaded"
                            end
                          end
                          
                          ign_score = Ignindex.find(key_summoner[0].ignindex_id)
                          Rails.logger.info "#{cron_st}: achievement refresh for #{ign_score.id}"
                          achievement_refresh(ign_score.id)
                          curent_ach = Achievement.find(ign_score.active_achievement)
                          if !curent_ach.nil?
                            achievement_play(cron_st, curent_ach, clock_active_status)
                            # experience_gain(cron_st, curent_ach, clock_active_status)
                            # spelling_vandor_name(cron_st, curent_ach, clock_active_status)
                          end

                          #Score.find_by_user_id(key_summoner[0].user_id).update(week_6: Score.find_by_user_id(key_summoner[0].user_id).week_6 + key_summoner[0].points)
                          #Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_6: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_6 + key_summoner[0].points)
                          Rails.logger.info "#{cron_st}: won 1/1 for #{key_summoner[0].summoner_id}"            
                        else 
                          Rails.logger.info "#{cron_st}: updated else for #{key_summoner[0].summoner_id}"
                        end                        
                      else # end of kind 5 or 6
                        Rails.logger.info "#{cron_st}: wrong kind for #{key_summoner[0].summoner_id}"
                      end
                    end
                    Rails.logger.info "#{cron_st}: Ran cycle num: #{times_run} for total mass of: #{mass_count}"
                  end

                end

              elsif response.timed_out?
                Rails.logger.info "#{cron_st}: Hydra timeout on cycle num: #{times_run} for mass of: #{mass_count}"
              elsif response.code == 0
                Rails.logger.info "#{cron_st}: Hydra issue (#{response.return_message}) on cycle num: #{times_run} for mass of: #{mass_count}"
              else
                Rails.logger.info "#{cron_st}: Hydra HTTP failed (#{response.code.to_s}) on cycle num: #{times_run} for mass of: #{mass_count}"
              end

            end
          end
          hydra.run
          het = Time.now
          puts "\n" + (het - hst).to_s() + " seconds for hydra"

          ct = Time.now.to_i
          hydra_food = []
          if (ct-cron_st) < times_run*11
            Rails.logger.info "#{cron_st}: Throttle for #{times_run*11-(ct-cron_st)} seconds"
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
        Rails.logger.info "#{cron_st}: ***hydra_food at start: #{hydra_food.count}"

        Rails.logger.info "#{cron_st}: ran hydra times_run is about to run for: #{times_run}"
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
                Rails.logger.info "#{cron_st}: games_hash matches are nil for someone!"
              else

                key_summoner = []
                hydra_food.each do |temp_status_looper|
                  if temp_status_looper.summoner_id == response.effective_url[52...(response.effective_url.length - 45)].to_i
                    puts "#{temp_status_looper.summoner_id} matched with  #{response.effective_url[52...(response.effective_url.length - 45)]}"
                    key_summoner << temp_status_looper
                  end
                end

                if key_summoner == []
                  Rails.logger.info "#{cron_st}: RIOT API ERROR: returning incorrect summonerid/name"
                else 
                  Rails.logger.info "#{cron_st}: ****key summoner_id = #{key_summoner[0].summoner_id}, matched from #{games_hash["matches"][0]["participantIdentities"][0]["player"]["summonerId"]}"

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
                    Rails.logger.info "#{cron_st}: nil valid_games for #{key_summoner[0].summoner_id}"
                  else
                    Rails.logger.info "#{cron_st}: valid_games for #{key_summoner[0].summoner_id}: #{valid_games}"
                    Rails.logger.info "#{cron_st}: win status: #{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}"
                    
                      if key_summoner[0].kind == 1
                        Rails.logger.info "#{cron_st}: challenge kind 1 for #{key_summoner[0].summoner_id}"
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
                          Rails.logger.info "#{cron_st}: updated lost first for #{key_summoner[0].summoner_id}"
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
                          Score.find_by_user_id(key_summoner[0].user_id).update(week_6: Score.find_by_user_id(key_summoner[0].user_id).week_6 + key_summoner[0].points)
                          Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_6: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_6 + key_summoner[0].points)
                          Rails.logger.info "#{cron_st}: won 1/1 for #{key_summoner[0].summoner_id}"            
                        else
                          Rails.logger.info "#{cron_st}: updated else for #{key_summoner[0].summoner_id}"
                        end  
                      elsif key_summoner[0].kind == 4
                        Rails.logger.info "#{cron_st}: challenge kind 4 for #{key_summoner[0].summoner_id}"
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
                          Rails.logger.info "#{cron_st}: updated lost first for #{key_summoner[0].summoner_id}"
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
                            Score.find_by_user_id(key_summoner[0].user_id).update(week_6: Score.find_by_user_id(key_summoner[0].user_id).week_6 + key_summoner[0].points)
                            Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_6: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_6 + key_summoner[0].points)
                            Rails.logger.info "#{cron_st}: won 1/1 for #{key_summoner[0].summoner_id}"    
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
                            Rails.logger.info "#{cron_st}: updated win with wrong champion for #{key_summoner[0].summoner_id}"
                          end
                        else
                          Rails.logger.info "#{cron_st}: updated else for #{key_summoner[0].summoner_id}"
                        end                       
                      elsif key_summoner[0].kind == 5 || key_summoner[0].kind == 6
                        Rails.logger.info "#{cron_st}: challenge kind #{key_summoner[0].kind} for #{key_summoner[0].summoner_id}"
                        if !games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          clock_active_status = Status.find(key_summoner[0].id)
                          clock_active_status.update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          clock_active_status.update(win_value: 0)

                          ign_score = Ignindex.find(key_summoner[0].ignindex_id)
                          curent_ach = Achievement.find(ign_score.active_achievement)
                          if !curent_ach.nil?
                            achievement_play(cron_st, curent_ach, clock_active_status)
                            # experience_gain(cron_st, curent_ach, clock_active_status)
                          end

                          Rails.logger.info "#{cron_st}: updated lost first for #{key_summoner[0].summoner_id}"
                        elsif games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]
                          clock_active_status = Status.find(key_summoner[0].id)
                          clock_active_status.update(game_1: {
                            :champion_id => "#{Champion.find(games_hash["matches"][valid_games[0]]["participants"][0]["championId"]).champion}", 
                            :matchCreation => "#{games_hash["matches"][valid_games[0]]["matchCreation"]}", 
                            :win_loss => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["winner"]}", 
                            :matchDuration => "#{games_hash["matches"][valid_games[0]]["matchDuration"]}", 
                            :kills => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["kills"]}", 
                            :deaths => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["deaths"]}", 
                            :assists => "#{games_hash["matches"][valid_games[0]]["participants"][0]["stats"]["assists"]}"
                            })
                          clock_active_status.update(win_value: 2)

                          ign_score = Ignindex.find(key_summoner[0].ignindex_id)

                          proc = rand(100..100)
                          Rails.logger.info "#{cron_st}: proc value is #{proc}"
                          
                          random_prize(cron_st, ign_score, clock_active_status)

                          ign_score = Ignindex.find(key_summoner[0].ignindex_id)
                          Rails.logger.info "#{cron_st}: achievement refresh for #{ign_score.id}"
                          achievement_refresh(ign_score.id)
                          curent_ach = Achievement.find(ign_score.active_achievement)
                          if !curent_ach.nil?
                            achievement_play(cron_st, curent_ach, clock_active_status)
                            # experience_gain(cron_st, curent_ach, clock_active_status)
                            # spelling_vandor_name(cron_st, curent_ach, clock_active_status)
                          end
                                                                             
                          #Score.find_by_user_id(key_summoner[0].user_id).update(week_6: Score.find_by_user_id(key_summoner[0].user_id).week_6 + key_summoner[0].points)
                          #Score.find_by_summoner_id(key_summoner[0].summoner_id).update(week_6: Score.find_by_summoner_id(key_summoner[0].summoner_id).week_6 + key_summoner[0].points)
                          Rails.logger.info "#{cron_st}: won 1/1 for #{key_summoner[0].summoner_id}"            
                        else 
                          Rails.logger.info "#{cron_st}: updated else for #{key_summoner[0].summoner_id}"
                        end                        
                      else # end of kind 5 or 6
                        Rails.logger.info "#{cron_st}: wrong kind for #{key_summoner[0].summoner_id}"
                      end # end of kind 5 or 6
                    end
                    Rails.logger.info "#{cron_st}: Ran cycle num: #{times_run} for total mass of: #{mass_count}"
                  end

              end

            elsif response.timed_out?
              Rails.logger.info "#{cron_st}: Hydra timeout on cycle num: #{times_run} for mass of: #{mass_count}"
            elsif response.code == 0
              Rails.logger.info "#{cron_st}: Hydra issue (#{response.return_message}) on cycle num: #{times_run} for mass of: #{mass_count}"
            else
              Rails.logger.info "#{cron_st}: Hydra HTTP failed (#{response.code.to_s}) on cycle num: #{times_run} for mass of: #{mass_count}"
            end

          end
        end
        hydra.run
        het = Time.now
        puts "\n" + (het - hst).to_s() + " seconds for hydra"

        ct = Time.now.to_i
        if (ct-cron_st) < times_run*11
          Rails.logger.info "#{cron_st}: Throttle for #{times_run*11-(ct-cron_st)} seconds"
          throttle_total += times_run*11-(ct-cron_st)
          sleep times_run*11-(ct-cron_st)
        end
      else
      end

    #end status remainder
    Rails.logger.info "#{cron_st}: completed challenges in #{Time.now.to_i - status_st} seconds!"
    Rails.logger.info "#{cron_st}: | Cron Duration: #{Time.now.to_i - cron_st} | Throttle: #{throttle_total} | API calls: #{val_count + api_call_count} | Total challenges: #{total_count} | API/second: #{(val_count + api_call_count)/(Time.now.to_i - cron_st).round(2)}/second | max @ #{(val_count + api_call_count*1.00)/(Time.now.to_i - cron_st - throttle_total)}/second | Timeouts: #{timeout_count} | Overloads #{api_overload_count}"
    #puts "#{Time.now.to_i} | Cron Duration: #{Time.now.to_i - cron_st} | Throttle: #{throttle_total} | API calls: #{val_count + api_call_count} | Total challenges: #{total_count} | API/second: #{(val_count + api_call_count)/(Time.now.to_i - cron_st).round(2)}/second | max @ #{(val_count + api_call_count*1.00)/(Time.now.to_i - cron_st - throttle_total)}/second | Timeouts: #{timeout_count} | Overloads #{api_overload_count}"

  end #end of api_call_status

  def self.random_prize(cron_st, ign, clock_active_status)
    Rails.logger.info "#{cron_st}: checking for random prize"

    if Prize.all.where("vendor = ?", "Cora Pizza").where("assignment = ?", 0).where("tier = ?", "2").where("delivered_at < ?", 12.hours.ago.to_i).count == 0
      Rails.logger.info "#{cron_st}: prize open, doing a roll"
      proc2 = rand(0..100)
      Rails.logger.info "#{cron_st}: proc2 is #{proc2}"
      if proc2 < 2 && Prize.all.where("vendor = ?", "Cora Pizza").where("assignment = ?", 0).where("tier = ?", "2").count > 0
        Rails.logger.info "#{cron_st}: rolled prize"
        assign_prize = Prize.all.where("vendor = ?", "Cora Pizza").where("assignment = ?", 0).where("tier = ?", "2").first
        assign_prize.update(
          :assignment => 1,
          :delivered_at => Time.now.to_i,
          :ignindex_id => ign.id)
        clock_active_status.update(
          :prize_id => assign_prize.id)
        ign.update(
          :prize_id => assign_prize.id)
        Rails.logger.info "#{cron_st}: assigned prize id #{assign_prize.id}"
      else
        Rails.logger.info "#{cron_st}: rolled no prize"
      end


    else
      Rails.logger.info "#{cron_st}: prize not open, no roll"

    end

    Rails.logger.info "#{cron_st}: finished for random prize"
  end

  def self.achievement_play(cron_st, ach, status)
    Rails.logger.info "#{cron_st}: achievement_up, status.win_value #{status.win_value}"

    if status.win_value == 2 # game won, all challenges use this so far
      ach.update(
        :wins_recorded => ach.wins_recorded += 1)
      Rails.logger.info "#{cron_st}: from game won (#{status.win_value}) ach_win #{ach_win}"
    else
      Rails.logger.info "#{cron_st}: from game won (#{status.win_value}) ach_win #{ach_win}"
    end

    if ach.can_spell_name_open.length > 0 #this achievement is available
      spell_letter(cron_st, ach, status)
    end

    Rails.logger.info "#{cron_st}: finished ach experience update"
  
  end

  def self.spell_letter(cron_st, ach, status)
      Rails.logger.info "#{cron_st}: ach spelling has length: #{ach.can_spell_name_open}"
      champion_letter = status.game_1[:champion_id][0]
      Rails.logger.info "#{cron_st}: champion_letter: #{champion_letter}"
      if ach.can_spell_name_open.include?(champion_letter)
        ach.update(
          :can_spell_name_open => ach.can_spell_name_open.sub(champion_letter, "")) 
        Rails.logger.info "#{cron_st}: ach spelling has new length: #{ach.can_spell_name_open}"
        Rails.logger.info "double check w/ table: #{Achievement.find(ach.id).can_spell_name_open}"
      else 
        "#{cron_st}: ach spelling has same length"
      end
      Rails.logger.info "#{cron_st}: spelling_vandor_name finished"    
  end

  # def self.experience_gain(cron_st, ach, status)
  #   Rails.logger.info "#{cron_st}: experience_gain, status.win_value #{status.win_value}"
  #   ach_win = 0
  #   ach_exp = 0

  #   if ach.can_spell_name_open.length > 0 #this achievement is available
  #     Rails.logger.info "#{cron_st}: ach spelling has length: #{ach.can_spell_name_open}"

  #     champion_letter = status.game_1[:champion_id][0]
  #     Rails.logger.info "#{cron_st}: champion_letter: #{champion_letter}"
  #     if ach.can_spell_name_open.include?(champion_letter)
  #       ach.update(
  #         :can_spell_name_open => ach.can_spell_name_open.sub(champion_letter, "")) 
  #       ach_exp = ach_exp += 1
  #       Rails.logger.info "#{cron_st}: ach spelling has new length: #{ach.can_spell_name_open}"
  #       Rails.logger.info "#{cron_st}: from game won (#{status.win_value}) ach_win #{ach_win}, ach_exp #{ach}"
  #       Rails.logger.info "double check w/ table: #{Achievement.find(ach.id).can_spell_name_open}"
  #     else 
  #       "#{cron_st}: ach spelling has new same length"
  #     end

  #     Rails.logger.info "#{cron_st}: spelling_vandor_name finished"
  #   end

  #   if status.win_value == 2 # game won
  #     ach_win = 1
  #     ach_exp = ach_exp += 1
  #     Rails.logger.info "#{cron_st}: from game won (#{status.win_value}) ach_win #{ach_win}, ach_exp #{ach_exp}"
  #   else
  #     Rails.logger.info "#{cron_st}: from game won (#{status.win_value}) ach_win #{ach_win}, ach_exp #{ach_exp}"
  #   end

  #   Rails.logger.info "#{cron_st}: increasing experience from: #{ach.experience_earned} by #{ach_exp}"
  #   Rails.logger.info "#{cron_st}: increasing games from: #{ach.games_played} by #{ach_win}"
  #   ach.update(
  #     :experience_earned => ach.experience_earned += ach_exp,
  #     :games_played => ach.games_played += ach_win)
  #   Rails.logger.info "#{cron_st}: finished ach experience update"

  #   Rails.logger.info "#{cron_st}: achievement win status: #{ach.experience_req >= ach.experience_earned}"
  #   if ach.experience_earned >= ach.experience_req   #acheivement is won
  #     ach.update(
  #       :result => 2)
  #     ach.ignindex.update(
  #       :active_achievement => nil,
  #       :ign_challenge_points => ach.ignindex.ign_challenge_points += 1)
  #   end
  #   Rails.logger.info "#{cron_st}: experience_gain finished"
  # end  

  def self.spelling_vandor_name(cron_st, ach, status, ach_exp)
    Rails.logger.info "#{cron_st}: ach spelling has length: #{ach.can_spell_name_open}"

    champion_letter = status.game_1[:champion_id][0]
    Rails.logger.info "#{cron_st}: champion_letter: #{champion_letter}"
    if ach.can_spell_name_open.include?(champion_letter)
      ach.update(
        :can_spell_name_open => ach.can_spell_name_open.sub(champion_letter, "")) 
      ach_exp = ach_exp += 1
      Rails.logger.info "#{cron_st}: ach spelling has new length: #{ach.can_spell_name_open}"
      Rails.logger.info "#{cron_st}: from game won (#{status.win_value}) ach_win #{ach_win}, ach_exp #{ach}"
      Rails.logger.info "double check w/ table: #{Achievement.find(ach.id).can_spell_name_open}"
    else 
      "#{cron_st}: ach spelling has new same length"
    end

    Rails.logger.info "#{cron_st}: spelling_vandor_name finished"
  end

  def self.achievement_refresh(session_ignindex_id) #input also takes current_user.ignindex_id
    Rails.logger.info "session_ignindex_id: #{session_ignindex_id}"
    gca_ign = Ignindex.where("id = ?", session_ignindex_id).first
    Rails.logger.info "gca_ign.id: #{gca_ign.id}"
    if gca_ign.active_achievement.nil?

      if Region.find(gca_ign.region_id).prize_id_tier1.nil? #fixes sloppy db default vars
        Region.find(gca_ign.region_id).update(
          :prize_id_tier1 => "[]")
      end

      if JSON.parse(Region.find(gca_ign.region_id).prize_id_tier1)[0] == 1
        prizing_here = 1
      else
        prizing_here = 0
      end
      gca_ach_search = Achievement.where("ignindex_id = ?", gca_ign.id).where("result IS ?", nil).where("kind = ?", prizing_here).first

      if gca_ach_search.nil?
        new_ach = Achievement.create(
          :ignindex_id => session_ignindex_id,
          :experience_req => 10,
          :can_spell_name => "CORA",
          :can_spell_name_open => "CORA",
          :description => "Earn 10 experience points to get an end of the week reward. Each win recoded is 1exp, winning game with a champion whose name starts with one of the letters CORA is 2exp.",
          :kind => prizing_here,
          :expire => 4.weeks.from_now.to_i )
        Ignindex.where("id = ?", session_ignindex_id).first.update(
          :active_achievement => new_ach.id)
      else        
        new_ach = gca_ach_search
        Ignindex.where("id = ?", session_ignindex_id).first.update(
          :active_achievement => new_ach.id)        
      end

      @achievement = new_ach
      number = @achievement.experience_earned/@achievement.experience_req
      @achievement_progress = number.round(2)
      
    else
      @achievement = Achievement.find(Ignindex.where("id = ?", session_ignindex_id).first.active_achievement)
    end
  end  


end