var auto_name_int;
var auto_name = function(){
  var auto_name_int = window.setInterval(function(){
    $('#summoner_name_text').html($('#input_id').val())
    console.log(new Date)
  },1000)
}

var teaser_summoner = function(){
  $('#button_teaser_summoner').on("click", function() {
    $('#js_name').html($('#input_teaser_summoner').val())
    
    $('#js_val').html('- Not Valid')
    $('#js_val').addClass('not-validated')
    $('#summoner_valid_panel').slideDown(1000)
    $('#js_validation_string').html("illbepro")
    $('#mastery_page_name').html("AP mid")
    $('#mastery_page_div').removeClass("start-ghost")
    $('#test_cd').data("timer", ( (new Date).getTime()/1000) )
    $('#check_loop').data("check", (new Date).getTime()/1000)
    clearTimeout(ignTimer)
    clearTimeout(ign_update_timeout)
    ign_clocks()     
  })
}

var ajax_button_validation_string = function() {
  $('#validation_code_submit').bind('ajax:success', function(evt, data, status, xhr) {
    $.ajax({
      url: "/ignindices/" + $("#ign").data("id"),
      type: "GET",
      dataType: "json",
      success: function(data) { 
        console.log(data)
        $('#js_validation_string').html(data.validation_string)
        $('#test_cd').data("timer", data.validation_timer)
      }
    })
  })
}

var ajax_button_summoner_name = function() {
  $('#summoner_name_submit').bind('ajax:success', function(evt, data, status, xhr) {
    $.ajax({
      url: "/ignindices/" + $("#ign").data("id"),
      type: "GET",
      dataType: "json",
      success: function(data) {
        new_name = data.summoner_name
        $('#summoner_panel').removeClass("panel-success panel-danger")
        $('#summoner_panel').addClass("panel-danger")
        $('#js_name').html(new_name)
        $('#js_val').html('- Not Valid')
        $('#js_val').removeClass('validated')
        if ( !$('#js_val').hasClass("not-validated") ) {
          $('#js_val').addClass('not-validated')
        }
        $('#summoner_valid_panel').slideDown(1000)
        $('#js_validation_string').html(data.validation_string)
        if ( data.mastery_1_name !== null ) {
          $('#mastery_page_div').removeClass("start-ghost")
          $('#mastery_page_name').html(data.mastery_1_name)
        $('#test_cd').data("timer", data.validation_timer)
        $('#check_loop').data("check", data.updated_at.to_i)
        clearTimeout(ignTimer)
        clearTimeout(ign_update_timeout)
        ign_clocks()
        ign_update()
        }
      }
    })
  });
};

var ign_update_timeout;

var ign_update = function() {
  val_timer = $('#test_cd').data("timer")
  if (val_timer > 0) { 
    $.ajax({
      url: "/ignindices/" + $("#ign").data("id"),
      type: "GET",
      dataType: "json",
      success: function(data) {
        console.log("ign update ran")
        mastery_1 = data.mastery_1_name
        // check for null
        if (mastery_1 !== null) {
          if ( $('#mastery_page_div').hasClass("start-ghost") ) {
            $('#mastery_page_div').toggleClass("start-ghost");
          }
          $('#mastery_page_name').html(mastery_1)
        };

        if (data.summoner_validated == true) {
          var jsval = '- Valid';
          $('#js_val').removeClass('not-validated')
          $('#js_val').addClass('validated')
          $('#summoner_panel').removeClass("panel-danger")
          $('#summoner_panel').addClass("panel-success")
          $('#summoner_valid_panel').slideUp(3000) // get rid of clock
            
            if ( $('#setup_progress_bar').length > 0 ) { // slide the setup over by 1
              setup_0_1() 
            }   

          } else {

          var jsval = '- Not valid';

            if (grab > (current_time/1000 - 300) ) {
              var ign_update_timeout = setTimeout( ign_update, 30000);
            }

          }
        $('#ign2').html(data.summoner_name);
        $('#js_val').html(jsval);
        }
    });
  }
}

var ignTimer;
var ign_clocks = function(){

  grab = $('#test_cd').data("timer") // validation timout counter
  grab2 = $('#check_loop').data("check") // clockwork estimate

  current_time = (new Date).getTime()
  now1 = parseInt((grab - (current_time/1000) + 300)/60) + "m " + parseInt((grab - (current_time/1000) + 300)%60) + "s"
  $('#test_cd').html(now1) // update total time left
  
  now2 = parseInt(30 - ((current_time/1000 - grab2) % 30))
  $('#check_loop').html(now2) // update estimate of clockwork
  
  console.log("ign timers updated")
  if (grab > (current_time/1000 - 300)) {
    if ($('#page_name').data("pagespec") == "ignindex_index") {
      ignTimer = setTimeout( ign_clocks, 1000);
    } else {
      // $('#validation_code_div').toggleClass("start-ghost")
      clearTimeout(ign_update_timeout);
    }
  }
};

// $(window).load(function(){
//   current_page = $('#page_name').data("pagespec")
//   if (current_page == "ignindex_index") {
//       console.log("this is ignindex_index")
//       ign_clocks()
//       ign_update()
//     } else {
//       console.log("this is not ignindex_index");
//     }
// });

$(document).ready(function(){
  current_page = $('#page_name').data("pagespec")
    if (typeof ignTimer !== 'undefined') {
     clearTimeout(ignTimer); 
    } 
  if (current_page == "ignindex_index") {
      console.log("this is ignindex_index")
      ign_clocks();
      ign_update();
      ajax_button_summoner_name();
      ajax_button_validation_string();
      teaser_summoner();
      // auto_name();
    } else {
      console.log("this is not ignindex_index");
    }  
})
$(document).on('page:load', function(){
    current_page = $('#page_name').data("pagespec")
    if (typeof ignTimer !== 'undefined') {
     clearTimeout(ignTimer); 
    }     
  if (current_page == "ignindex_index") {
      console.log("this is ignindex_index")
      ign_clocks();
      ign_update();
      ajax_button_summoner_name();
      ajax_button_validation_string();
      teaser_summoner();
      // auto_name();
    } else {
      console.log("this is not ignindex_index");
    }  
})

$(window).unload(function(){
  clearTimeout(ignTimer)
  clearTimeout(ign_update_timeout)
})
