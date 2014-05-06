# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
 # $(".update_watched").on("ajax:success", (e, data, status, xhr) ->
 #   alert "success"
   # json_data = JSON.parse xhr.responseText
  # $("#watched_img_97642").attr('src', '/assets/watched.png')
 # )
  #.bind "ajax:error", (e, xhr, status, error) ->
#    alert "error"

$(document).ready ->
  $(".update_watched").on("ajax:success", (e, data, status, xhr) ->
    json_data = JSON.parse xhr.responseText
    if json_data.movie_id
      if json_data.watched == true      
        $("#watched_img_above_" + json_data.movie_id).attr('src', '/assets/watched.png')
        $("#watched_img_" + json_data.movie_id).attr('src', '/assets/watched_remove.png')
      else
        $("#watched_img_" + json_data.movie_id).attr('src', '/assets/watched_add.png')  
        $("#watched_img_above_" + json_data.movie_id).attr('src', '') 
    else
      $("#watched_img_" + json_data.movie_id).attr('src', '/assets/watched_add.png')  
      $("#watched_img_above_" + json_data.movie_id).attr('src', '')       
  ).bind "ajax:error", (e, xhr, status, error) ->
    
  $(".update_collected").on("ajax:success", (e, data, status, xhr) ->
    json_data = JSON.parse xhr.responseText
    if json_data.movie_id
      if json_data.collection == true      
        $("#collected_img_above_" + json_data.movie_id).attr('src', '/assets/collected.png')
        $("#collected_img_" + json_data.movie_id).attr('src', '/assets/collected_remove.png')
      else
        $("#collected_img_" + json_data.movie_id).attr('src', '/assets/collected_add.png')   
        $("#collected_img_above_" + json_data.movie_id).attr('src', '')
    else
      $("#collected_img_" + json_data.movie_id).attr('src', '/assets/collected_add.png')    
      $("#collected_img_above_" + json_data.movie_id).attr('src', '')     
  ).bind "ajax:error", (e, xhr, status, error) -> 
  
  $(".update_watchlist").on("ajax:success", (e, data, status, xhr) ->
    json_data = JSON.parse xhr.responseText
    if json_data.movie_id
      if json_data.watchlist == true      
        $("#watchlist_img_above_" + json_data.movie_id).attr('src', '/assets/watchlist.png')
        $("#watchlist_img_" + json_data.movie_id).attr('src', '/assets/watchlist_remove.png')
      else
        $("#watchlist_img_" + json_data.movie_id).attr('src', '/assets/watchlist_add.png')  
        $("#watchlist_img_above_" + json_data.movie_id).attr('src', '') 
    else
      $("#watchlist_img_" + json_data.movie_id).attr('src', '/assets/watchlist_add.png')  
      $("#watchlist_img_above_" + json_data.movie_id).attr('src', '')       
  ).bind "ajax:error", (e, xhr, status, error) ->
    
  
  