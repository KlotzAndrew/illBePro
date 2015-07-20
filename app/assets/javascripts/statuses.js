var button_game_start = function() {
  $('#start_game_track').bind('ajax:success', function(evt, data, status, xhr) {
    js_game_starting()
    button_cancel_needs_status_id()
  })
}

var button_game_end = function() {
  $('#end_game_track').bind('ajax:success', function(evt, data, status, xhr) {
    js_game_ending()
  })
}

button_cancel_needs_status_id = function(){
    $.ajax({
        url: "/statuses",
        type: "GET",
        dataType: "json",
        success: function(data) {
            console.log(data)
            console.log(data.id)
            chal_timer = Date.parse(data.created_at)/1000 + data.value
            $('#challenge_timer').data("chal_time_value", chal_timer)
            $('#cg_id').data('status_id', data.id)
            $('#end_game_track').attr('action', '/statuses/' + data.id)
            $('#button_get_results').attr('action', '/statuses/' + data.id)
        }
    })

}

var js_game_starting = function(){
    console.log("game starting")
    $('#button-game-cancel').removeClass("start-ghost")
    $('#start_game_track').addClass("start-ghost")
    $('#current_created_at').removeClass("start-ghost")

    $('#spinner_toggle').removeClass("start-ghost")
    $('#stats_toggle').addClass("start-ghost")

    $('#game_track_timer').removeClass("start-ghost")
}

var js_game_ending = function(){
    console.log("game ending")
    $('#button-game-cancel').addClass("start-ghost")
    $('#start_game_track').removeClass("start-ghost")
    $('#current_created_at').addClass("start-ghost")

    $('#spinner_toggle').addClass("start-ghost")
    $('#stats_toggle').removeClass("start-ghost")

    $('#game_track_timer').addClass("start-ghost")
}

var offline_alert = function() {
    $('#new_chal_button').on("click", function(){
        alert("illBePro engine is temporarily offline! Check out our Facebook or Twitter page for updates!")
    })
};

var start_challenge = function(){
    $('#show_chal').hide(); // hide challenge
    $('#show_chal').toggleClass("start-ghost", false); // hidden challenge has visibility
    $('#roll_prizes').hide(); // remove proc roller
    $('#show_chal').fadeIn(2500); // fadein hidden challenge

};


var finish_button = function(){
    $('#hit-unfinish').on("click", function(){
        console.log("hit-unfinish clicked");
        $('#hit-unfinish').toggleClass("start-ghost");
        $('#hit-finish').toggleClass("start-ghost");
    });

    $('#hit-finish').on("click", function(){
        console.log("hit-finish clicked");
        $('#hit-unfinish').toggleClass("start-ghost");
        $('#hit-finish').toggleClass("start-ghost");
        
        if (checking_game == false) {
            check_game()
            console.log("button triggered check-game")
        }
    });        
};

checking_game = false
var check_game = function(){
    $.ajax({
        url: "/statuses/" + $('#cg_id').data('status_id'),
        type: "GET",
        dataType: "json",
        success: function(data) {
            console.log(data)
            if ((data !== null) && (data.win_value !== null)) {
                // document.location.reload(true);
                if (data.prize_id !== null) {
                    // document.location.reload(true);
                } else {
                    console.log("game updated")
                    js_game_ending()

                    checking_game = false                
                    kills = data.game_1["kills"]
                    deaths = data.game_1["deaths"]
                    assists = data.game_1["assists"]
                    game_summary = kills + "/" + deaths + "/" + assists

                    duration = Math.round(data.game_1["matchDuration"]/60)

                    $('#game_champion').html(data.game_1["champion_id"])
                    $('#game_kda').html(game_summary)
                    // $('#game_length').html(duration)
                    
                }
                clearInterval(checkint)
                clearTimeout(statusTimer);      
            } else {
                var checkint = setTimeout(check_game, 15000)
                checking_game = true
            }
        }
    });
};

var challenge_timer = function(){
    console.log("timers updated")
    current_time = (new Date).getTime()
    grab = $('#challenge_timer').data("chal_time_value") // validation timout counter
    adj_grab = +grab + +pause_guess
    now1 = parseInt((adj_grab - (current_time/1000))/60) + "m " + parseInt((adj_grab - (current_time/1000))%60) + "s"
  
    current_created_at = $('#current_created_at').data("current_created") // pause button to finish button, not actual time left
    
    final_two = +adj_grab - +current_time/1000
    if ( final_two < 120 ) {
        if ( $('#cg-refresher').hasClass("cg-update-true") ) {
        } else  {
            $('#cg-refresher').addClass("cg-update-true") 
            console.log("timer triggered check-game")
            // clearInterval(game_check_int)
            check_game()
        }
    }


  if ( !$('#hit-pause').hasClass("start-ghost") ) {
      $('#challenge_timer').html(now1) // update total time left
  } else {
    pause_guess += 1
  }
    var statusTimer = setTimeout( challenge_timer, 1000)
};

pause_guess = 0




var is_page_status = function(){
    console.log("status setup running") 
    current_page = $('#page_name').data("pagespec")  
    
    if (typeof statusTimer !== 'undefined') {
       clearTimeout(checkint); 
    } 

  if (current_page == "status_index") {
      console.log("this is status_index")
      challenge_timer()
      finish_button()
      button_game_start()
      button_game_end()
        
     if ( $('#cg-refresher').hasClass("cg-update-true") ) {
        // window.clearInterval(game_check_int)
        check_game()
      } else {
        var checkint;
      }
    } else {
      console.log("this is not status_index");
    }  
}

$(window).unload(function(){
    clearTimeout(statusTimer);
    clearTimeout(checkint);
    console.log("cleard sttus timer");
})

// $(document).on('page:load', function() {
//     console.log("working? s")
//     is_page_status();
// })

// $(document).ready(function() {
//     console.log("working? s")
//     is_page_status();
// })