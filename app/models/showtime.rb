class Showtime < ActiveRecord::Base
  belongs_to :movie
  
  def self.udpate_showtimes_slovenia
    require 'rubygems'
    require 'nokogiri'
    require 'open-uri'      
    cities = ['maribor', 'ljubljana', 'Celje', 'Kranj', 'Koper', 'novo-mesto', 'murska-sobota', 'crnomelj', 'domzale', 'Izola', 'krsko', 'Metlika', 'nova-gorica', 'Ptuj',
      'Sezana', 'slovenj-gradec', 'smarje-pri-jelsah', 'Trbovlje', 'Velenje', 'Zagorje', 'Kamnik', 'Bled', 'Brezice', 'gornja_radgona', 'Grosuplje',
      'Izlake', 'Jesenice', 'Kocevje', 'Pivka', 'Radovljica', 'rogaska-slatina', 'Sevnica', 'skofja-loka', 'slovenske-konjice', 'smarjeske-toplice', 'Tolmin', 'Vrhnika', 'ziri']
    time = Time.now
    dates = [time.strftime('%d.%m.%Y')]
    6.times do
      dates << (dates.last.to_date + 1.day).strftime('%d.%m.%Y')
    end
    
   # imdb = OMDB.title('Banditenkinder - slovenskemu narodu ukradeni otroci')
    
    cities.each do |city|
      dates.each do |date|
    #date =  dates.second 
    #city = cities.first
        url = "http://www.gremovkino.si/kino-spored/" + date + "/" + city
        doc = Nokogiri::HTML(open(url))
        puts doc.at_css("title").text
        count = 1
        doc.css(".scheduleItem").each do |item|
          movie_info = item.at_css(".rightData/.movieInfo")
          is3D = '3D' unless movie_info.at_css(".clearfix/.movieIsIn3D").nil?
          if !item.css(".leftData/a[href]/img").first.nil?
            poster = 'http://www.gremovkino.si' + item.css(".leftData/a[href]/img").first['src']
          end
          isSynchronized = 'Synchronized' unless item.at_css(".leftData/.sync").nil?
          title = movie_info.at_css(".clearfix/h2/a").text unless movie_info.at_css(".clearfix/h2/a").nil?
          original_title = movie_info.at_css(".clearfix/h2/.org_name").text unless movie_info.at_css(".clearfix/h2/.org_name").nil?
          if !movie_info.css(".scheduleItemRow")[1].nil?
            directors = movie_info.css(".scheduleItemRow")[1].text.split(':')[1].strip.split(',')
          end
          
          if !title.nil?        
            showtimes = {}
            cinema = nil
            movie_info.search('.scheduleCellData').each do |link|
              shedules = link.search('.sheduleTime2')
              if shedules.count > 0
                shedules.each do |shedule|
                  if shedule.text[/[0-9][0-9]:[0-9][0-9]/]
                    showtimes[cinema] << shedule.text[/[0-9][0-9]:[0-9][0-9]/] 
                  end
                end
              else        
                cinema = link.text.strip   
                showtimes = { cinema => [] }         
              end        
            end
            
            showtimes.each do |key, location| 
              location.each do |show|
               # puts "location " + key
               # puts "show " + show
                
                movie = nil
                movies = Movie.where(:title => original_title)
                if movies.count > 1 && directors && directors.count > 0
                  movies.each do |m|
                    puts "\n MORE THAN ONE ORIGINAL!!!!!!!: " + m.to_yaml
                    puts " DIRECTORS:  " + m.directors.to_yaml
                    m.directors.each do |d|
                      if d.name == directors.first.strip
                         puts " FOUND!!!!!!!"
                        movie = m
                        break
                      end
                    end
                    #if !movie                   
                    #  continue
                    #end
                  end
                else 
                  movie = movies.first
                end
                                
                if !movie 
                  movies = Movie.where(:title => title)
                  if movies.count > 1 && directors  && directors.count > 0
                    movies.each do |m|
                      m.directors.each do |d|
                        if d.name == directors.first.strip
                           puts " FOUND!!!!!!!"
                          movie = m
                          break
                        end
                      end
                    end
                  else 
                    movie = movies.first
                  end
                end 
                if !movie 
                  search = Tmdb::Search.new
                  search.resource('movie') 
                  if original_title
                    search.query(original_title)
                  else
                    search.query(title)
                  end
                  results = search.fetch
                  if results && results.first
                    movie = Movie.find_by_tmdb_id(results.first.id)
                    if !movie
                      movie = Movie.add_movie(results.first.id, nil, nil) 
                    end
                  end
                end     
                if !movie 
                  if original_title
                    imdb = OMDB.title(original_title)
                  else
                    imdb = OMDB.title(title)
                  end
                                    
                  if imdb && imdb.response == 'True'
                    puts "\n !!!! IMDB ID: " + imdb.imdb_id + "\n"
                    movie = Movie.find_by_imdb_id(imdb.imdb_id)
                    if !movie
                      result = Tmdb::Find.imdb_id(imdb.imdb_id)
                      puts "\n !!!! result ID: " + result.to_yaml + "\n"
                      if result && result.movie_results && result.movie_results.first
                        movie = Movie.find_by_tmdb_id(result.movie_results.first.id)
                        if !movie
                          movie = Movie.add_movie(result.movie_results.first, nil, nil) 
                        end
                      else
                        movie = Movie.add_movie_with_omdb(imdb)
                      end               
                    end
                  else
                    if !movie
                      if original_title
                        imdb = Imdb::Search.new(original_title)
                      else
                        imdb = Imdb::Search.new(title)
                      end
                      if imdb.movies.size > 0
                        puts "\n !!!! IMDB ID: " + imdb.movies.first.to_yaml + "\n"
                        movie = Movie.find_by_imdb_id('tt' + imdb.movies.first.id)
                        if !movie
                          result = Tmdb::Find.imdb_id('tt' + imdb.movies.first.id)
                          puts "\n !!!! result ID: " + result.to_yaml + "\n"
                          if result && result.movie_results && result.movie_results.first
                            movie = Movie.find_by_tmdb_id(result.movie_results.first.id)
                            if !movie
                              movie = Movie.add_movie(result.movie_results.first.id, nil, nil) 
                            end
                          else
                            movie = Movie.add_movie_with_imdb(imdb.movies.first, poster, directors)
                          end               
                        end
                      end                        
                    end
                  end
                end
                
                datetime = date.to_datetime.change(:hour => show.to_time.hour, :min => show.to_time.min, :sec => 0)
                
                if datetime > Time.now
                  if movie     
                    showtime = Showtime.find_by_movie_id_and_datetime(movie.id, datetime)
                    puts "\n SHOWTIME FOUND: " + showtime.to_yaml
                  end
      
                  if !showtime
                    showtime = Showtime.new
                    if movie 
                      showtime.movie = movie
                    end 
                    showtime.title = title
                    showtime.original_title = original_title unless original_title.nil?
                    showtime.city = city
                    showtime.country =  'Slovenia'
                    showtime.is_3d = true unless is3D.nil?
                    showtime.is_synchronized = true unless isSynchronized.nil?
                    showtime.cinema = key
                    showtime.datetime = datetime
                    puts "\n SHOWTIME NOT!!! FOUND: " + showtime.to_yaml
                    showtime.save
                  end
                end
              end
            end        
            count +=1
          end
        end
      end
    end
    showtimes_for_delete = Showtime.where("datetime <= ?", Time.now)
    puts "DELETE: " + showtimes_for_delete.to_yaml
    showtimes_for_delete.destroy_all
  end
end
