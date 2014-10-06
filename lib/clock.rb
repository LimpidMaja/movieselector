require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)
require 'clockwork'

#include Clockwork

#every(4.minutes, 'Queueing interval job') { Delayed::Job.enqueue IntervalJob.new }
#every(1.day, 'Queueing scheduled job', :at => '14:17') { Delayed::Job.enqueue ScheduledJob.new }

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  # handler receives the time when job is prepared to run in the 2nd argument
  # handler do |job, time|
  #   puts "Running #{job}, at #{time}"
  # end

  #every(10.seconds, 'frequent.job')
  every(5.minutes, 'update_trakt_trending') { List.update_trakt_trending }
  #every(1.hour, 'hourly.job')

  every(1.day, 'midnight_top_250_update', :at => '00:01')  {List.update_imdb_top_250 }
  every(1.day, 'midnight_showtimes_slovenia_update', :at => '00:01') { Showtime.udpate_showtimes_slovenia }
  
end