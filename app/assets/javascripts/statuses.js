var offline_alert = function() {
    $('#new_chal_button').on("click", function(){
        alert("illBePro engine is temporarily offline! Check out our Facebook or Twitter page for updates!")
    })
}

var start_challenge = function(){
    $('#show_chal').hide(); // hide challenge
    $('#show_chal').toggleClass("start-ghost", false); // hidden challenge has visibility
    $('#roll_prizes').hide(); // remove proc roller
    $('#show_chal').fadeIn(2500); // fadein hidden challenge

    // if ( $('#page_name').hasClass("teaser-config") ) {
    //     setTimeout(function(){
    //         document.location.reload()
    //     }, 60000)
    // }
};

var pause_button = function(){ 
    $('#hit-unpause').on("click", function(){
        console.log("hit-unpause clicked");
        $('#hit-unpause').toggleClass("start-ghost");
        $('#hit-pause').toggleClass("start-ghost");
    });

    $('#hit-pause').on("click", function(){
        console.log("hit-pause clicked");
        $('#hit-unpause').toggleClass("start-ghost");
        $('#hit-pause').toggleClass("start-ghost");
    });
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
        
        if ( $('#cg-refresher').hasClass("cg-update-true") ) {
        } else  {
            $('#cg-refresher').toggleClass("cg-update-true") 
            console.log("button triggered check-game")
            check_game()    
        }
    });        
};

var check_game = function(){
    $.ajax({
        url: "/statuses/" + $("#cg_id").data("status_id"),
        type: "GET",
        dataType: "json",
        success: function(data) {
            console.log(data)
            if (data.win_value !== null) {
                
                if (data.prize_id !== null) {
                    document.location.reload(true);
                } else {

                    $('#v3_ingame').addClass("start-ghost")
                    $('#v3_outgame').removeClass("start-ghost")                

                    champ = data.game_1["champion_id"]
                    kills = data.game_1["kills"]
                    deaths = data.game_1["deaths"]
                    assists = data.game_1["assists"]
                    game_summary = "played as " + champ + " " + kills + "/" + deaths + "/" + assists


                    if (data.win_value == 2) { // won game
                        $('#v3_prize_results').html("Won your game, but no prize this time")
                        $('#v3_game_results').html(game_summary)
                    } else { // loss or timeout
                        $('#v3_prize_results').html("Lost your game")
                        $('#v3_game_results').html(game_summary)
                    }
                    $('#game_end_instructions').html("Every game has a random chance for a prize")

                }
                clearInterval(checkint)
                clearTimeout(statusTimer);      
            } else {
                var checkint = setTimeout(check_game, 15000)
                console.log(data.win_value)
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

  if ( (current_time/1000 - current_created_at) > 1200  ) { // if after 20 min, auto change button from pause to finish
    if ( $('#after-20').hasClass("start-ghost") ) { //check if page was loaded befor 20, else nothing
        $('#after-20').toggleClass("start-ghost");
        $('#before-20').toggleClass("start-ghost");
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

$(document).ready(function(){
    current_page = $('#page_name').data("pagespec")

    if (typeof statusTimer !== 'undefined') {
       clearTimeout(statusTimer); 
    } 
    if (current_page == "status_index") {
        console.log("this is status_index")
        challenge_timer()
        pause_button()
        finish_button()

      if ( $('#cg-refresher').hasClass("cg-update-true") ) {
        console.log("check game on doc ready")
        // clearInterval(game_check_int)
        check_game()
      } else {
        var checkint;
      }
    } else {
      console.log("this is not status_index");
    }  
})

$(document).on('page:load', function(){
    current_page = $('#page_name').data("pagespec")  
    if (typeof statusTimer !== 'undefined') {
       clearTimeout(checkint); 
    } 
  if (current_page == "status_index") {
      console.log("this is status_index")
      challenge_timer()
      pause_button()
      finish_button()
        
     if ( $('#cg-refresher').hasClass("cg-update-true") ) {
        // window.clearInterval(game_check_int)
        check_game()
      } else {
        var checkint;
      }
    } else {
      console.log("this is not status_index");
    }  
})  

$(window).unload(function(){
    clearTimeout(statusTimer);
    clearTimeout(checkint);
    console.log("cleard sttus timer");
})

// $(document).ready(challenge_timer) // triggers on pages it shouldnt be
// $(document).on('page:load', challenge_timer);

// $(document).ready(pause_button)
// $(document).on('page:load', pause_button);

// $(document).ready(finish_button)
// $(document).on('page:load', finish_button);

// $(document).ready(proc_number)
// $(document).on('page:load', proc_number);
