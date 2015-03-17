/*
var pollActivity = function() {
  $.ajax({
    url: "/ignindices/" + $("#ign").data("id"),
    type: "GET",
    dataType: "json",
    success: function(data) {
    	console.log(data)
      console.log("rand poller2")
      if (data.summoner_validated == true) {
        var jsval = '<h1 class="validated"><strong>Validated!</strong></h1>';
        } else {
        var jsval = '<h1 class="not-validated"><strong>Not validated!</strong></h1>';
        }
      $('#ign2').html(data.summoner_name);
      $('#js_val').html(jsval);
      if (data.validation_timer == null) { 
        } else {
          setTimeout( pollActivity, 5000);
          }
      }
  });
}

window.onload = function(){
  setInterval(function() {
  grab = $('#test_cd').data("timer")
  current_time = (new Date).getTime();
  now1 = parseInt((grab - (current_time/1000) + 300)/60) + "m " + parseInt((grab - (current_time/1000) + 300)%60) + "s"
  $('#test_cd').html(now1)

  grab2 = $('#check_loop').data("check")
  now2 = parseInt(60 - ((current_time/1000 - grab2) % 60))
  $('#check_loop').html(now2)
  }, 1000);
};


window.onload = pollActivity
window.onunload = function() {}; */