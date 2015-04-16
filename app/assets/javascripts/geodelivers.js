
var geo_submit = function(){
  $('#geo_json_submit').on("click", function(){
    console.log("clicked it geo json")
    setTimeout(function(){
      $.ajax({
        url: "/geodelivers",
        type: "GET",
        dataType: "json",
        success: function(geo_data) {
          if (geo_data["json_geodeliver"]["region_id"] == null) {
            vendor_info = 'Enter a Prize Zone to see prizes are available'
          } else {
            if (geo_data["json_all_prize_desc"].length == 0) {
              vendor_info = 'No prizes for this zone right now'
            } else {
              vendor_info = 'Thiz zone is prized by </br> <strong><i> ' + geo_data["json_all_prize_vendor"][0] + '</i></strong>'
              if ( $('#setup_progress_bar').length > 0 ) { // slide the setup over by 1
                setup_1_2() 
              }
            }
          }
          $('#prize_sponsor').html(vendor_info);

          $('#geo_status').removeClass("panel-danger")
          $('#geo_status').removeClass("panel-success")
          if (geo_data["json_geodeliver"]["address"] == 0) {
            valid_status = '<h3 class="validated"><strong>Valid: </strong>'+ geo_data["json_region_city"]+ ', ' + geo_data["json_region_country"] + '</h3>' 
            $('#geo_status').addClass("panel-success")
          } else if (geo_data["json_geodeliver"]["address"] == null ) {
            valid_status = '<h3 class="not-validated">Prize Zone is empty</h3>'
            $('#geo_status').addClass("panel-danger")
          } else {
            valid_status = '<h3 class="not-validated">This Prize Zone is not valid</h3>'
            $('#geo_status').addClass("panel-danger")
          }
          $('#geo_results').html(valid_status);
        }
      });
    }, 1500)
  })
}

$(document).ready(geo_submit) // nothing happens if wrong page
$(document).on('page:load', geo_submit); // nothing happens if wrong page