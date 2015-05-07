var offline_alert = function() {
    $('#new_chal_button').on("click", function(){
        alert("illBePro engine is temporarily offline! Check out our Facebook or Twitter page for updates!")
    })
}



var proc_number = function(){
    var user_cp = $('#cp_div').data("cp") // update roll, then highlight prize
    // $('#proc_button').on("click", function() {
        $('#proc_button').toggleClass("start-ghost")
        console.log("clicked it");

        var open_proc_1 =  Math.floor((Math.random() * 100) + 1) // first roll
        var open_proc_2 =  Math.floor((Math.random() * 100) + 1) // first roll
        var open_proc_3 =  Math.floor((Math.random() * 100) + 1) // first roll
        var open_proc_4 =  Math.floor((Math.random() * 100) + 1) // first roll
   
        var highlight_prize = []; // builds highlighting object for prize roll
        $.each($('.dp-selector'), function(index, value) { 
            highlight_prize.push($(this)[0].id); 
        });
        highlight_prize.shift()

        // figure out what type of prize is being highlighted (zomg refracor this qq)
        if (open_proc_1 > user_cp) {
            var display_roll_1 = "display_prize_0"
        } else {
            var display_roll_1 = highlight_prize[Math.floor(Math.random()*highlight_prize.length)];
        }

        if (open_proc_2 > user_cp) {
            var display_roll_2 = "display_prize_0"
        } else {
            var display_roll_2 = highlight_prize[Math.floor(Math.random()*highlight_prize.length)];
        }

        if (open_proc_3 > user_cp) {
            var display_roll_3 = "display_prize_0"
        } else {
            var display_roll_3 = highlight_prize[Math.floor(Math.random()*highlight_prize.length)];
        }                

        if (open_proc_4 > user_cp) {
            var display_roll_4 = "display_prize_0"
        } else {
            var display_roll_4 = highlight_prize[Math.floor(Math.random()*highlight_prize.length)];
        }

        // first roll display
        var proc_push = '<span class="btn btn-primary roll-button"> ' + open_proc_1 + ' </span>'
        $('#proc_div').html(proc_push);
            $('#proc_div').toggleClass("start-invis")
        setTimeout(function(){ // first blink
 
        $('#' + display_roll_1).toggleClass("panel-default")
        $('#' + display_roll_1).toggleClass("panel-primary")     
        $('#proc_div').toggleClass("start-invis")      

        setTimeout(function(){ // second roll
            console.log("second roll")
            $('#' + display_roll_1).toggleClass("panel-primary")   // reset first highlight        
            $('#' + display_roll_1).toggleClass("panel-default")
            $('#proc_div').toggleClass("start-invis")
            
            setTimeout(function(){ // second roll blinker
            $('#proc_div').toggleClass("start-invis")
            var proc_push = '<h6><span class="btn btn-primary roll-button"> ' + open_proc_2 + ' </span></h6>'
            $('#proc_div').html(proc_push); // update roll then hightlight prize

            $('#' + display_roll_2).toggleClass("panel-default")
            $('#' + display_roll_2).toggleClass("panel-primary")           

            setTimeout(function(){ // reveal the final prize
                console.log("4th roll")            
                $('#' + display_roll_2).toggleClass("panel-primary")           
                $('#' + display_roll_2).toggleClass("panel-default")
                $('#proc_div').toggleClass("start-invis")
                
                setTimeout(function(){ // 4th roll blinker

                var proc = $('#proc_div').data("proc")
                $('#proc_div').toggleClass("start-invis")
                var proc_push = '<h6><span class="btn btn-primary roll-button"> ' + proc + ' </span></h6>'
                $('#proc_div').html(proc_push);

                if (proc < user_cp){
                    
                    var display_real_prize = $('#current_prize_desc').data("cpd")

                    $('#display_prize_' + display_real_prize).toggleClass("panel-default")
                    $('#display_prize_' + display_real_prize).toggleClass("panel-primary")

                    setTimeout(function(){
                        $('#display_prize_' + display_real_prize).toggleClass("panel-primary")
                        $('#display_prize_' + display_real_prize).toggleClass("panel-default")
                        setTimeout(function(){
                            $('#display_prize_' + display_real_prize).toggleClass("panel-default")
                            $('#display_prize_' + display_real_prize).toggleClass("panel-primary")

                            
                            setTimeout(function(){
                                highlight_prize.splice(display_real_prize-1, 1)
                                // $('#display_prize_0').toggleClass("start-ghost")
                                highlight_prize.forEach(function(prize_desc){
                                    $('#' + prize_desc).fadeOut(1500)
                                })
                                $('#display_prize_0').fadeOut(1500)

                                setTimeout(function(){
                                start_challenge()
                                }, 3500)

                            },500)
                        },500)
                    },500)

                } else {
                    var display_real_prize = $('#current_prize_desc').data("cpd")

                    $('#display_prize_' + display_real_prize).toggleClass("panel-default")
                    $('#display_prize_' + display_real_prize).toggleClass("panel-primary")

                    setTimeout(function(){
                        $('#display_prize_' + display_real_prize).toggleClass("panel-primary")
                        $('#display_prize_' + display_real_prize).toggleClass("panel-default")
                        setTimeout(function(){
                            $('#display_prize_' + display_real_prize).toggleClass("panel-default")
                            $('#display_prize_' + display_real_prize).toggleClass("panel-primary")

                            
                            setTimeout(function(){
                               // highlight_prize.splice(display_real_prize-1, 1)
                                // $('#display_prize_0').toggleClass("start-ghost")
                                highlight_prize.forEach(function(prize_desc){
                                    $('#' + prize_desc).fadeOut(1500)
                                })
                                //$('#display_prize_0').fadeOut(1500)

                                setTimeout(function(){
                                start_challenge()
                                }, 3500)

                            },500)
                        },500)
                    },500)  
                }

                }, 500) // blinker for 4th roll
            }, 1500) // end 4th roll 
            }, 500); //blinker for second roll
        }, 1500);// end seonc roll
        },500)
    // }); // this makes it auto run
};

var proc_number_press = function(){
    $('#proc_button').on("click", function(){
        proc_number()
    })
}

var reveal_results = function(){
    user_cp = $('#cp_div').data("cp")
    proc = $('#proc_div').data("proc")

    var proc_push = '<h2><span class="btn btn-success roll-button"> Proc: ' + proc + ' </span></h2>'
    $('#proc_div').html(proc_push);
    if (proc < user_cp){
        $('#result_yes').hide(); // hide result
        $('#result_yes').toggleClass("start-ghost", false); // hidden results have visibility
        $('#result_yes').fadeIn(1500); // fade in hidden results
    } else {
        $('#result_no').hide(); // hide result
        $('#result_no').toggleClass("start-ghost", false); // hidden results have visibility
        $('#result_no').fadeIn(1500); // fade in hidden results        
    }
    setTimeout(start_challenge, 2500);
};

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
            if (data.win_value == null) {
                
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


                    if (data.win_value !== 2) { // won game
                        $('#v3_prize_results').html("Won your game, but no prize this time")
                        $('#v3_game_results').html(game_summary)
                    } else { // loss or timeout
                        $('#v3_prize_results').html("Lost your game")
                        $('#v3_game_results').html(game_summary)
                    }
                    if ( $('#setup_progress_bar').length > 0 ) { // slide the setup over by 1
                        setTimeout(function() {
                            setup_2_3()
                        }, 3000);
                    } 
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
