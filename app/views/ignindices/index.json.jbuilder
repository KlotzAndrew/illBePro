json.array!(@ignindices) do |ignindex|
  json.extract! ignindex, :id, :user_id, :summoner_name, :summoner_id, :summoner_validated, :validation_string, :validation_timer
  json.url ignindex_url(ignindex, format: :json)
end

// var pollActivity = function() {
//   $.ajax({
//     url: Routes.ignindices_path ({format: 'json' }),
//     type: "GET",
//     dataType: "json",
//     success: function(data) {
//       console.log(data);
//     }
//   });
// }

// setInterval( pollActivity, 500);