class Status < ActiveRecord::Base

  validate :dr_who, :on => :create
  validate :one_fox_one_gun, :on => :create

  belongs_to :ignindex

  serialize :game_1, Hash
  serialize :game_2, Hash
  serialize :game_3, Hash
  serialize :game_4, Hash
  serialize :game_5, Hash

  def factory_test
    Rails.logger.info "User.all.count:: #{User.all.count}"
    self.update(summoner_name: "working")
  end


  def dr_who #this makes sure summoner is valid + region is entered
    ignindex = self.ignindex
    if ignindex.summoner_validated != true
      errors.add(:summoner_required, '- You need a summoner name before you can start a challenge!')
    elsif ignindex.region_id.nil?
      errors.add(:region_required, '- You need to select a prize zone to start a challenge')
    end
  end

  def one_fox_one_gun #this is 1 game/user + concurrent requests/API
    ignindex = self.ignindex
    if ignindex.statuses.where("win_value IS ?", nil).count > 0
      errors.add(:you_can, 'only have 1 challenge running at a time!')
    elsif Status.all.where("created_at >= ?", Time.now - 60.seconds).count > 19
      errors.add(:start_queue, ' is full! Try back in 60 seconds')
    else
      Rails.logger.info "no errors"
    end
  end

  def self.api_call
    Rails.logger.info "*****STARTING CLOCKWORK*****"
    Staticpage.find(1).update(
        :league_api_ping => Time.now.to_i) #this is used for UX purposes

    @cron_st = Time.now.to_i #used for searching logs
    @val_count = 0 #total API calls used for validations
    @throttle_total = 0 #seconds throttled
    @mass_count = 0 #only fire 8 API calls per 10s

    section_league_summoner #SECTION_1: league summoner/by-name endpoint
    section_league_summoner_byname  #SECTION_2: league summoner endpoint
    section_league_matchhistory #SECTION_3: league matchistory endpoint

    #end status remainder
    Rails.logger.info "#{@cron_st}: | Cron Duration: #{Time.now.to_i - @cron_st} | Throttle: #{@throttle_total} | API calls: #{@val_count + @api_call_count} | Total challenges: #{@challenge_count} | API/second: #{(@val_count + @api_call_count)/(Time.now.to_i - @cron_st).round(2)}/second | max @ #{(@val_count + @api_call_count.round)/(Time.now.to_i - @cron_st - @throttle_total.round(2))}/second | Timeouts: #{@timeout_count} | Overloads #{@api_overload_count}"
  end

  def self.section_league_summoner
    mass_summoner_names = ""
    val_st = Time.now.to_i
    Ignindex.where("validation_timer > ?", 0 ).each do |x|
      if x.validation_timer < (Time.now.to_i - 600)
        Rails.logger.info "#{x.summoner_name} ran out of time"
        x.update(validation_timer: nil)
        x.update(validation_string: nil)
      else
        Rails.logger.info "#{@cron_st}: #{x.summoner_name} still has #{600 + x.validation_timer - Time.now.to_i} seconds!"
        if x.summoner_id.nil?
          Rails.logger.info "#{@cron_st}: #{x.summoner_name} summoner.id is nill"
          if x.summoner_name_ref != x.summoner_name.mb_chars.downcase.gsub(' ', '').to_s
            x.update(summoner_name_ref: "#{x.summoner_name.mb_chars.downcase.gsub(' ', '').to_s}")
          end
          
          if mass_summoner_names.length > 0 then mass_summoner_names << "," end
          mass_summoner_names << "#{x.summoner_name.downcase}"

          if mass_summoner_names.split(',').count > 0 && mass_summoner_names.split(',').count%40 == 0
            league_summoner_byname(mass_summoner_names)
            mass_summoner_names = ""
          end

        else
          Rails.logger.info "#{@cron_st}: already have id for #{x.summoner_name}"
        end
      end
    end

    if (mass_summoner_names.split(',').count > 40 && mass_summoner_names.split(',').count%40 != 0) or (mass_summoner_names.split(',').count < 40 && mass_summoner_names.split(',').count != 0)
      league_summoner_byname(mass_summoner_names)
      mass_summoner_names = ""
    end
    Rails.logger.info "#{@cron_st}: completed league_summoner_byname in #{Time.now.to_i - val_st} seconds!"    
  end

  def self.section_league_summoner_byname
    mass_summoner_ids = ""
    Ignindex.where("validation_timer > ?", 0 ).where.not(summoner_id: nil).each do |x|
      if mass_summoner_ids.length > 0 then mass_summoner_ids << "," end 
      mass_summoner_ids << "#{x.summoner_id}"
      total_queued = mass_summoner_ids.split(',').count

      if total_queued > 0 && total_queued%40 == 0
        league_summoner(mass_summoner_ids)
        mass_summoner_ids = ""
      end 
    end 

    total_queued = mass_summoner_ids.split(',').count
    if (total_queued > 40 && total_queued%40 != 0) or (total_queued < 40 && total_queued != 0)
      league_summoner(mass_summoner_ids)
      mass_summoner_ids = ""      
    end
    Rails.logger.info "#{@cron_st}: completed validations in #{Time.now.to_i - @cron_st} seconds!"    
  end

  def self.section_league_matchhistory
    status_st = Time.now.to_i #required for logger
    @challenge_count = 0 #total number of active challenges
    @api_call_count = 0 #calls used for matchhistory
    @timeout_count = 0 #calls stopped for throttle timer
    @api_overload_count = 0 #calls stopped for throttle max
    @times_run = 0 #counter for hydra groups fired (groups of 8)

    throttle = true
    trigger_timer_bench = 300 #queues status for 5 consecutive API calls
    hydra_food = [] #queued status objects for hydra call
    all_status = Status.where(win_value: nil).order(created_at: :desc)
    if all_status.count < 8 then throttle = false end #disengage throttle (helps w/ testing)
    
    all_status.each do |status| #=> all active statuses
      @challenge_count += 1
      @mass_count += 1
      if Time.now.to_i - @cron_st > 55
        @timeout_count += 1
      elsif @mass_count > 40
        @api_overload_count += 1
      else

        if status.trigger_timer.nil? then status.update(trigger_timer: 0) end

        if Time.now.to_i - status.created_at.to_i - status.value > 0 #=> terminate timeouts
          Rails.logger.info "#{@cron_st}: Status: #{status.summoner_name} has timed out"
          status.update(win_value: 1)
        elsif ((Time.now.to_i - status.created_at.to_i - status.value) > -119) or (status.trigger_timer > (Time.now.to_i - trigger_timer_bench)) 
          @mass_count += 1
          hydra_food << status
          Rails.logger.info "#{@cron_st}: add to hydra for #{status.summoner_name} on #{@times_run}/#{@mass_count}"
          if @mass_count > 0 && @mass_count%8 == 0 
            league_matchhistory(hydra_food, throttle)
            hydra_food = []
          end
        end
      end
    end


    if (@mass_count > 8 && @mass_count%8 != 0) or (@mass_count < 8 and @mass_count !=0)
      league_matchhistory(hydra_food, throttle)
      hydra_food = []
    end
    Rails.logger.info "#{@cron_st}: completed challenges in #{Time.now.to_i - status_st} seconds!"    
  end

  def self.league_summoner(mass_summoner_ids)
    @val_count += 1
    @mass_count += 1
    url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/#{mass_summoner_ids}/masteries?api_key=" + Rails.application.secrets.league_api_key
    begin
      mastery_data = open(url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
      mastery_hash = JSON.parse(mastery_data)
      
      mastery_hash.each_pair do |key,value|

        ign_for_mastery_hash = Ignindex.where("summoner_id = ?", key).first
        ign_for_mastery_hash.update(mastery_1_name: "#{mastery_hash["#{key}"]["pages"][0]["name"]}")
        Rails.logger.info "#{@cron_st}: 1st page name: #{mastery_hash["#{key}"]["pages"][0]["name"]}"
        Rails.logger.info "#{@cron_st}: 1st page name should be: #{ign_for_mastery_hash.validation_string}"

        if "#{mastery_hash["#{key}"]["pages"][0]["name"]}" == ign_for_mastery_hash.validation_string

        Rails.logger.info "ign_for_mastery_hash.validation_timer: #{ign_for_mastery_hash.validation_timer}"
        Rails.logger.info "User.find_by_summoner_id(ign_for_mastery_hash.validation_timer).nil?: #{User.find_by_summoner_id(ign_for_mastery_hash.validation_timer).nil?}"
        
        #WIP attach_user
        add_a_user = nil
        user = User.where("summoner_id = ?", ign_for_mastery_hash.validation_timer).first
        if user.nil? #check if any user has vaidator
          Rails.logger.info "#{@cron_st}: attach_user nope:}"
        else
          user.update(
            :ignindex_id => ign_for_mastery_hash.id)
          Rails.logger.info "#{@cron_st}: attach_user yes:"
          Rails.logger.info "#{@cron_st}: ign_for_mastery_hash.id: #{ign_for_mastery_hash.id}"

          add_a_user = user.id
        end

        ign_for_mastery_hash.update(
          :last_validation => ign_for_mastery_hash.validation_timer,
          :summoner_validated => true,
          :validation_timer => nil,
          :validation_string => nil,
          :user_id => add_a_user,
          :region_id => ign_for_mastery_hash.region_id_temp)
        Rails.logger.info "#{@cron_st}: key validated"

        else
          Rails.logger.info "#{@cron_st}: key not validated"
        end
      end
    rescue Timeout::Error
      Rails.logger.info "#{@cron_st}: URI-TIMEOUT request on masteries"
    rescue => e
      Rails.logger.info "#{@cron_st}: uri error request on masteries 1"
    end    
  end

  def self.league_summoner_byname(mass_summoner_names)
    @val_count += 1
    @mass_count += 1
    Rails.logger.info "#{@cron_st}: Running api call for (#{mass_summoner_names})"
    url = "https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/#{mass_summoner_names}?api_key=" + Rails.application.secrets.league_api_key
    begin
      Rails.logger.info "#{@cron_st}: #{@cron_st}: Running API call successfully for mass_summoner_names on name"
      summoner_data = open(URI.encode(url),{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,:read_timeout=>3}).read
      summoner_hash = JSON.parse(summoner_data)     
      Rails.logger.info "#{@cron_st}: #{summoner_hash}"
        summoner_hash.each_pair do |summoner_hash_key,summoner_hash_value|

          Ignindex.where("summoner_name_ref = ?", summoner_hash_key).first.update(summoner_id: summoner_hash["#{summoner_hash_key}"]["id"])

        end
    rescue Timeout::Error
      Rails.logger.info "#{@cron_st}: URI-TIMEOUT request for mass_summoner on name"
    rescue => e
      Rails.logger.info "#{@cron_st}: uri error request for mass_summoner on name"
    end    
  end

  def self.league_matchhistory(hydra_food, throttle)
    @times_run += 1
    @api_call_count += hydra_food.count
    Rails.logger.info "#{@cron_st}: ***hydra_food at start: #{hydra_food.count}"

    Rails.logger.info "#{@cron_st}: ran hydra @times_run is about to run for: #{@times_run}st time"
    hydra = Typhoeus::Hydra.new(:max_concurrency => 200)
    hydra_food.each do |food|
      url = "https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/#{food.summoner_id}?api_key=" + Rails.application.secrets.league_api_key
      request = Typhoeus::Request.new(url, :timeout => 3)
      hydra.queue(request)
      request.on_complete do |response|
        if response.success?
          
          games_hash = JSON.parse(response.body)
          games_hash["matches"].sort_by {|match| match["matchCreation"]}.reverse

          if games_hash["matches"].nil? #if API returns nil data
            Rails.logger.info "#{@cron_st}: games_hash matches are nil for someone!"
          else

            status = hydra_food.select {|x| x.summoner_id == request.url[52...(request.url.length - 45)].to_i}.first

            if status.nil?
              Rails.logger.info "#{@cron_st}: RIOT API ERROR: returning incorrect summonerid/name"
            else 
              Rails.logger.info "#{@cron_st}: ****key summoner_id = #{status.summoner_id}, matched from #{games_hash["matches"][0]["participantIdentities"][0]["player"]["summonerId"]}"

              valid_games = []
              games_hash["matches"].each do |match|
                if match["queueType"] == "RANKED_SOLO_5x5"
                  if (match["matchCreation"]/1000 - match["matchDuration"]) >= (status.created_at.to_i - 420)
                    valid_games << match
                  end
                end
              end

              Rails.logger.info "#{@cron_st}: valid_games for #{status.summoner_id}: #{valid_games.count}"
              if valid_games[0].nil?
                Rails.logger.info "#{@cron_st}: nil valid_games for #{status.summoner_id}"
              else
                Rails.logger.info "#{@cron_st}: win status: #{valid_games[0]["participants"][0]["stats"]["winner"]}"
                
                if status.kind == 5
                  Rails.logger.info "#{@cron_st}: challenge kind #{status.kind} for #{status.summoner_id}"
                  status = Status.find(status.id)
                  ignindex = Ignindex.find(status.ignindex_id)
                  curent_ach = Achievement.where("id = ?", ignindex.active_achievement).first
                  status.update(game_1: {
                    :champion_id => "#{Champion.find(valid_games[0]["participants"][0]["championId"]).champion}", 
                    :matchCreation => "#{valid_games[0]["matchCreation"]}", 
                    :win_loss => "#{valid_games[0]["participants"][0]["stats"]["winner"]}", 
                    :matchDuration => "#{valid_games[0]["matchDuration"]}", 
                    :kills => "#{valid_games[0]["participants"][0]["stats"]["kills"]}", 
                    :deaths => "#{valid_games[0]["participants"][0]["stats"]["deaths"]}", 
                    :assists => "#{valid_games[0]["participants"][0]["stats"]["assists"]}"
                    })

                  if !valid_games[0]["participants"][0]["stats"]["winner"]
                    status.update(win_value: 0)
                    
                    if !curent_ach.nil?
                      achievement_play(curent_ach, status)
                    end
                    Rails.logger.info "#{@cron_st}: lost 0/1 for #{status.summoner_id}"

                  else valid_games[0]["participants"][0]["stats"]["winner"]
                    status.update(win_value: 2)

                    if !curent_ach.nil?
                      achievement_play(curent_ach, status)
                    end                                                                       
                    Rails.logger.info "#{@cron_st}: won 1/1 for #{status.summoner_id}"            
                  end                        
                end 
              end
              Rails.logger.info "#{@cron_st}: Ran cycle num: #{@times_run} for total mass of: #{@mass_count}"
            end

          end

        elsif response.timed_out?
          Rails.logger.info "#{@cron_st}: Hydra timeout on cycle num: #{@times_run} for mass of: #{@mass_count}"
        elsif response.code == 0
          Rails.logger.info "#{@cron_st}: Hydra issue (#{response.return_message}) on cycle num: #{@times_run} for mass of: #{@mass_count}"
        else
          Rails.logger.info "#{@cron_st}: Hydra HTTP failed (#{response.code.to_s}) on cycle num: #{@times_run} for mass of: #{@mass_count}"
        end

      end
    end
    hydra.run

    if throttle == true
      league_throttle 
    end
  end

  def self.league_throttle
    ct = Time.now.to_i
    if (ct-@cron_st) < @times_run*11
      Rails.logger.info "#{@cron_st}: Throttle for #{@times_run*11-(ct-@cron_st)} seconds"
      @throttle_total += @times_run*11-(ct-@cron_st)
      sleep @times_run*11-(ct-@cron_st)
    end     
  end

  def self.achievement_play(ach, status) #this trigggers each achivement condition method 
    Rails.logger.info "#{@cron_st}: achievement_up, status.win_value #{status.win_value}"

    if !ach.challenge.wins_required.nil?
      games_won(ach, status)
    end

    if !ach.challenge.can_spell_name.nil? && (ach.can_spell_name_open.length > 0)
      spell_letter(ach, status)
    end

    if !ach.challenge.con_wins_required.nil?
      consecutive_games_won(ach, status)
    end

    Rails.logger.info "#{@cron_st}: finished ach experience update"
  end

  def self.consecutive_games_won(ach, status)
    if status.win_value == 2
      ach.update(
        :con_wins_recorded => ach.con_wins_recorded += 1)
    else
      ach.update(
        :con_wins_recorded => 0)
    end    
  end

  def self.games_won(ach, status)
    if status.win_value == 2
      ach.update(
        :wins_recorded => ach.wins_recorded += 1)
    end
  end

  def self.spell_letter(ach, status)
      champion_letter = status.game_1[:champion_id][0]
      if ach.can_spell_name_open.include?(champion_letter)
        ach.update(
          :can_spell_name_open => ach.can_spell_name_open.sub(champion_letter, "")) 
      else 
      end
      Rails.logger.info "#{@cron_st}: spelling_vandor_name finished"    
  end

end