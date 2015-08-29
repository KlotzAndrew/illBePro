require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)
require 'clockwork'

include Clockwork

module Clockwork
configure do |config|
	config[:logger] = Logger.new("clockwork.log")
end


  handler do |job|
    puts "Running #{job}"
  end

  # handler receives the time when job is prepared to run in the 2nd argument
  # handler do |job, time|
  #   puts "Running #{job}, at #{time}"
  # end

  every(1.minute, 'api_caller.job') {LeagueApi.api_call}
  #every(1.day, 'index_builder.job') {Geodeliver.build_index}

end