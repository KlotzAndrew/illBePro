// var temp_user = function(){ // disabled
//   $('#temp_geodeliver_button').on("click", function() {
//     dataString = $('#temp_geodeliver_input').val()
//       $.ajax({
//         type: 'PUT',
//         url:  '/ignindices/',
//         data: dataString,
//         dataType: "JSON",
//         success: function(data) {
//             console.log(data);
//             console.log(dataString);
//         }
//       });

//     // 
//   })
// }


var auto_name_int;
var auto_name = function(){
  var auto_name_int = window.setInterval(function(){
    $('#summoner_name_text').html($('#input_id').val())
    console.log(new Date)
  },1000)
}

// var teaser_summoner = function(){
//   $('#button_teaser_summoner').on("click", function() {
//     $('#js_name').html($('#input_teaser_summoner').val())
    
//     $('#js_val').html('- Not Valid')
//     $('#js_val').addClass('not-validated')
//     $('#summoner_valid_panel').slideDown(1000)
//     $('#js_validation_string').html("illbepro")
//     $('#mastery_page_name').html("AP mid")
//     $('#mastery_page_div').removeClass("start-ghost")
//     $('#test_cd').data("timer", ( (new Date).getTime()/1000) )
//     $('#check_loop').data("check", (new Date).getTime()/1000)
//     clearTimeout(ignTimer)
//     clearTimeout(ign_update_timeout)
//     ign_clocks()     
//   })
// }

var landing_search = function() {
  console.log("ls ready")
  
  $('#landing_search_button').on('ajax:success', function(event, data, status, xhr) {
  console.log("ls hit")
  window.location.replace("../setup")
});

//   $('#landing_search_button').submit(function() {  
//     console.log("ls aim")
//       var valuesToSubmit = $(this).serialize();
//       $.ajax({
//           type: "POST",
//           url: $(this).attr('../ignindices#create'), //sumbits it to the given url of the form
//           data: valuesToSubmit,
//           dataType: "JSON" // you want a difference between normal and ajax-calls, and json is standard
//       }).success(function(json){
//           console.log("success", json);
//           console.log("ls hit")
//       });
//       return false; // prevents normal behaviour
//     console.log("ls fire")
//   });
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

  // this sets timeout to 0, if there is no timer running
  // if ( (grab - (current_time/1000) + 300) < 0 ) { 
  //   now1 = "0m 0s"
  //   } else {
      now1 = parseInt((grab - (current_time/1000) + 300)/60) + "m " + parseInt((grab - (current_time/1000) + 300)%60) + "s"
  //   }

  $('#test_cd').html(now1) // update total time left
  
  now2 = parseInt(60 - ((current_time/1000 - grab2) % 60))
  $('#check_loop').html(now2) // update estimate of clockwork
  
  console.log("ign timers updated")
  if (grab > (current_time/1000 - 300)) {
    if ($('#page_name').data("pagespec") == "ignindex_index") {
      ignTimer = setTimeout( ign_clocks, 1000);
    } else {
      // $('#validation_code_div').toggleClass("start-ghost")
      clearTimeout(ign_update_timeout);
    }
  } else { 
    // set timers to 0, if there is no active validation
    now1 = ""
    now2 = 0
    $('#test_cd').html(now1)
    $('#check_loop').html(now2)
  }
};

// can delete this, i think
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
  landing_search();
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
