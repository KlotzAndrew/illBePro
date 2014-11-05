namespace :my_namespace do
  desc "testing rake tasks"
	
	task :turn_off_alarm do
    	puts "Turned off alarm. Would have liked 5 more minutes, though."
  	end

  	task :list_values => :environment do
      stat = Status.all
      @stat.each do |t|
        puts t
      end
  		puts "Status Count: #{Status.count}"
  	end

	task :turn_off_alarm2 do
    	puts "Turned off alarm. Would have liked 5000000 more minutes, though."
      @status1 = Status.all
      @status1.each do |status|
        status.update_value
      end
  	end

	task :winner => :environment do
    	@Status.where(name: 'teemo').each do |score|
        score.update_attribute :content, "rake'd"
      end
  	end



  task :new_task => :environment do
        Status.where("value > 2").find_each do |status|
      status.update(value: Time.now.to_i - 1413594199)
      puts status.value
    end
  end

end
