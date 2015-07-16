var open_summoner = function(){
  $('#toggle_change_summoner').hover(function(){
    $('#toggle_change_summoner').addClass("active-blue");
  }, function(){
    $('#toggle_change_summoner').removeClass("active-blue");
  })

  $('#toggle_change_summoner').on("click", function(){
    $('#summoner_panel').toggleClass("start-ghost")
  })

}

var s2_refresh_button = function(){
  $('#s2-refresh').hover(function(){
    $('#s2-refresh').removeClass("active-blue");
  }, function(){
    $('#s2-refresh').addClass("active-blue");
  })

  $('#s2-refresh').on("click", function() {
    console.log("it clicked")

    $.ajax({
     url: "/ignindices/" + $("#ign").data("id"),
     type: "PUT",
     data: {"commit" : "Generate Validation Code" },
     dataType: "json",
     success: function(data) {
        console.log("it submitted!");
       }
     });

    $.ajax({
      url: "/ignindices/" + $("#ign").data("id"),
      type: "GET",
      dataType: "json",
      success: function(data) { 
        console.log(data)
        $('#js_validation_string').html(data["ignindex"].validation_string)
        $('#js_validation_string_intro').html(data["ignindex"].validation_string)
        $('#how_to_going').slideDown()
        $('#test_cd').data("timer", data["ignindex"].validation_timer)
        clearTimeout(ignTimer)
        clearTimeout(ign_update_timeout)
        ign_clocks()
        ign_update()
      }
    })
  })
}

var s2_spinner_visible = function(){
  if ($('#s2-check-spinner').hasClass("fa fa-spinner fa-pulse")) {
    $('#s2-check-spinner').removeClass("fa fa-spinner fa-pulse");
  }
}

var challenge_hover_highlight = function(){
  $('#challenge-s-cora1').hover(function(){
    $('#challenge-i-cora1').addClass("highlight-prize-info");
    }, function(){
    $('#challenge-i-cora1').removeClass("highlight-prize-info");
  }); 
}


var auto_name_int;
var auto_name = function(){
  var auto_name_int = window.setInterval(function(){
    $('#summoner_name_text').html($('#input_id').val())
    console.log(new Date)
  },1000)
}

var landing_search = function() {
  $('#landing_search_button').on('ajax:success', function(event, data, status, xhr) {
    window.location.replace("../setup")
  });

}


var ajax_button_validation_string = function() {
  $('#validation_code_submit').bind('ajax:success', function(evt, data, status, xhr) {
    $.ajax({
      url: "/ignindices/" + $("#ign").data("id"),
      type: "GET",
      dataType: "json",
      success: function(data) { 
        console.log(data)
        $('#js_validation_string').html(data["ignindex"].validation_string)
        $('#js_validation_string_intro').html(data["ignindex"].validation_string)
        $('#how_to_going').slideDown()
        $('#test_cd').data("timer", data["ignindex"].validation_timer)
        clearTimeout(ignTimer)
        clearTimeout(ign_update_timeout)
        ign_clocks()
        ign_update()
      }
    })
  })
}

var ajax_button_summoner_name = function() {
  $('#summoner_name_submit').bind('ajax:success', function(evt, data, status, xhr) {
    document.location.reload(true)
    // $.ajax({
    //   url: "/ignindices/" + $("#ign").data("id"),
    //   type: "GET",
    //   dataType: "json",
    //   success: function(data) {
    //     new_name = data["ignindex"].summoner_name
    //     $('#summoner_panel').removeClass("panel-success panel-danger")
    //     $('#summoner_panel').addClass("panel-danger")
    //     $('#js_name').html(new_name)
    //     $('#js_val').html('- Not Valid')
    //     $('#js_val').removeClass('validated')
    //     if ( !$('#js_val').hasClass("not-validated") ) {
    //       $('#js_val').addClass('not-validated')
    //     }
    //     $('#summoner_valid_panel').slideDown(1000)
    //     $('#js_validation_string').html(data["ignindex"].validation_string)
    //     if ( data["ignindex"].mastery_1_name !== null ) {
    //       $('#mastery_page_div').removeClass("start-ghost")
    //       $('#mastery_page_name').html(data["ignindex"].mastery_1_name)
    //     $('#test_cd').data("timer", data["ignindex"].validation_timer)
    //     $('#check_loop').data("check", data["ignindex"].updated_at.to_i)
    //     clearTimeout(ignTimer)
    //     clearTimeout(ign_update_timeout)
    //     ign_clocks()
    //     ign_update()
    //     }
    //   }
    // })
  });
};

var ign_update_timeout;
var valid_status = false
var ign_update = function() {
  val_timer = $('#test_cd').data("timer")
  if (val_timer > 0) { 
    $.ajax({
      url: "/ignindices/" + $("#ign").data("id"),
      type: "GET",
      dataType: "json",
      success: function(data) {
        console.log("ign update ran")
        mastery_1 = data["ignindex"].mastery_1_name
        // check for null
        if (mastery_1 !== null) {
          if ( $('#mastery_page_div').hasClass("start-ghost") ) {
            $('#mastery_page_div').toggleClass("start-ghost");
          }
          $('#mastery_page_name').html(mastery_1)
          $('#mastery_page_name_intro').html(mastery_1)
        };

        if (data["valid"] == true) {
          var jsval = '- Valid';
          $('#js_val').removeClass('not-validated')
          $('#js_val').addClass('validated')
          $('#summoner_panel').removeClass("panel-danger")
          $('#summoner_panel').addClass("panel-success")
          $('#summoner_valid_panel').slideUp(3000) // get rid of clock
          $('#how_to_going').slideUp(3000)
          // get rid of how to-stuff

          // $('#how_to_going').addClass("start-ghost")
          $('#how_to_finished').removeClass("start-ghost")
            
            // if ( $('#setup_progress_bar').length > 0 ) { // slide the setup over by 1
            //   setup_0_1() 
            // }   

          } else {

          var jsval = '- Not Valid Yet';

            // if (grab > (current_time/1000 - 600) ) {
            //   var ign_update_timeout = setTimeout( ign_update, 30000);
            // }

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

  now1 = "expires in: " + parseInt((grab - (current_time/1000) + 600)/60) + "m "// + parseInt((grab - (current_time/1000) + 300)%60) + "s"
  
  $('#test_cd').html(now1) // update total time left
  
  now2 = parseInt(60 - ((current_time/1000 - grab2) % 60))
  $('#check_loop').html(now2) // update estimate of clockwork

  if (now2 < 1) {
    $('#s2-currently-is').effect("bounce", 2000)
    ign_update();
  };

  if (grab > (current_time/1000 - 600)) {
    if ($('#page_name').data("pagespec") == "ignindex_index") {
      s2_panel2_green();
      ignTimer = setTimeout( ign_clocks, 1000);
    } else {
      // $('#validation_code_div').toggleClass("start-ghost")
      clearTimeout(ign_update_timeout);
    }
  } else { 
    // set timers to 0, if there is no active validation
    s2_panel2_red();
    now1 = "Code Expired!"
    $('#s2-check-spinner').removeClass("fa fa-spinner fa-pulse")
    now2 = 0
    $('#test_cd').html(now1)
    $('#check_loop').html(now2)
  }
};

var s2_panel2_green = function(){
  if ($('#s2-should-be').hasClass("panel-danger")) {
    $('#s2-should-be').removeClass("panel-danger");
    $('#s2-should-be').addClass("panel-success");
  }
}

var s2_panel2_red = function(){
    if ($('#s2-should-be').hasClass("panel-success")) {
      $('#s2-should-be').removeClass("panel-success");
      $('#s2-should-be').addClass("panel-danger");
  }
}


var is_page_ignindex = function(){
    console.log("ignindex setup running") 
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
      // auto_name();
    } else {
      console.log("this is not ignindex_index");
    }  
}

$(window).unload(function(){
  clearTimeout(ignTimer)
  clearTimeout(ign_update_timeout)
})

$(document).on('page:load', function() {
  console.log("working? i + s")
  is_page_ignindex();
  is_page_status();
  is_page_landing_page();

  challenge_hover_highlight();
  s2_refresh_button();
  open_summoner();
})

$(document).ready(function() {
  console.log("working? i + s")
  is_page_ignindex();
  is_page_status();
  is_page_landing_page();

  challenge_hover_highlight();
  s2_refresh_button();
  open_summoner();
})