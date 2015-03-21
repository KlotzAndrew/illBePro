
var ign_update = function() {
  val_timer = $('#test_cd').data("timer")
      if (val_timer == null) { 
        } else {
        $.ajax({
          url: "/ignindices/" + $("#ign").data("id"),
          type: "GET",
          dataType: "json",
          success: function(data) {
            console.log(data)
            console.log("ign update ran")
            if (data.summoner_validated == true) {
              var jsval = '<h1 class="validated"><strong>Validated!</strong></h1>';
              $('#ign_hide_1').fadeOut(5000)
              } else {
              var jsval = '<h1 class="not-validated"><strong>Not validated!</strong></h1>';
              }
            $('#ign2').html(data.summoner_name);
            $('#js_val').html(jsval);
            }
        });
      setTimeout( ign_update, 10000);
      }
}

var ign_clocks = function(){

  grab = $('#test_cd').data("timer") // validation timout counter
  grab2 = $('#check_loop').data("check") // clockwork estimate
 
  current_time = (new Date).getTime()
  now1 = parseInt((grab - (current_time/1000) + 300)/60) + "m " + parseInt((grab - (current_time/1000) + 300)%60) + "s"
  $('#test_cd').html(now1)
  now2 = parseInt(60 - ((current_time/1000 - grab2) % 60))
  $('#check_loop').html(now2)
  
  console.log("timers updated")
  if (grab > (current_time/1000 - 300)) {
    setTimeout( ign_clocks, 1000);
  }
};

$(window).load(function(){
  current_page = $('#page_name').data("pagespec")
  if (current_page == "ignindex_index") {
      console.log("this is ignindex_index")
      ign_clocks()
      ign_update()
    } else {
      console.log("this is not ignindex_index");
    }
});

window.onunload = function() {}; 
