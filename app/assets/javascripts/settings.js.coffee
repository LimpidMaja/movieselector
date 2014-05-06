# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
#$(document).ready ->
  #$("#trakt_update").on("ajax:success", (e, data, status, xhr) ->
   # json_data = JSON.parse xhr.responseText
    
   # text = '<b><span id="upload_text"> ' + json_data.upload_percent + '/' + json_data.upload_movie_count + ' Movies Added</span></b>'
        
    #$("#trakt_update").append text
    #upload_state = json_data.upload_state
    
    #setInterval () ->
   #   if upload_state == true 
   #     $.ajax $('#edit_link' ).attr('href') + '/../check_trakt_import_state',
    #      type: 'GET'
     #     dataType: 'json'
      #    error: (jqXHR, textStatus, errorThrown) ->
      #    #  alert "error"
      #      $("#upload_text").text "<b> Error Adding Movies! Try Again!</b>"
      #    success: (data, textStatus, xhr) ->
    #        json_data = JSON.parse xhr.responseText
    #        upload_state = json_data.upload_state
    #        text = ' ' + json_data.upload_percent + '/' + json_data.upload_movie_count + ' Movies Added'
    #        $("#upload_text").text text
    #     #   alert "append"
    #, 2000
        
 # ).bind "ajax:error", (e, xhr, status, error) ->
  #  $("#trakt_update").append "<b> Error Adding Movies! Try Again!</b>"