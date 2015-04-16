// $(document).ready(function(){
// 	setTimeout(function(){
// 		$('#setup_0').hide("slide", { direction: "left" }, 2000)
// 			$('#setup_progress_bar').css("width", '50%')			
// 		setTimeout(function(){
// 			$('#setup_1').show("slide", { direction: "right" }, 2000)
// 			setTimeout(function(){
// 				$('#setup_1').hide("slide", { direction: "left" }, 2000)
// 					$('#setup_progress_bar').css("width", '75%')
// 				setTimeout(function(){
// 					$('#setup_2').show("slide", { direction: "right" }, 2000)
// 				})
// 			}, 2000)
// 		},2000)
// 	},2000)
// })

// <img src="img/chardin.png" data-intro="An awesome 18th-century painter, who found beauty in everyday, common things." data-position="right" />
 var statusTimer;
  var checkint;
var setup_0_1 = function(){
	$(document).ready(function(){
		setTimeout(function(){
			$('#page_name').data("pagespec", "geodelivers_index")
			$('#setup_0').hide("slide", { direction: "left" }, 2000)
				$('#bread_1').removeClass("active")
				$('#bread_1').addClass("checked selectable")
				$('#bread_2').addClass("active")
			setTimeout(function(){
				$('#setup_1').show("slide", { direction: "right" }, 2000)
				$('#summonerIntro').removeClass("start-invis")
				// introJs().start('#summonerIntro')
				introJs().goToStep(2).start()
			},2000);
		},2000);
	});	
}

var setup_1_2 = function(){
	$(document).ready(function(){
		setTimeout(function(){
			$('#page_name').data("pagespec", "status_index")
			$('#setup_1').hide("slide", { direction: "left" }, 2000)
				$('#bread_2').removeClass("active")
				$('#bread_2').addClass("checked selectable")
				$('#bread_3').addClass("active")		
			setTimeout(function(){
				$('#setup_2').show("slide", { direction: "right" }, 2000)
				setTimeout(function(){
					document.location.reload(true);
				}, 2500)
			},2000);
		},2000);
	});	
}

var setup_2_3 = function(){
	$(document).ready(function(){
		setTimeout(function(){
				$('#bread_3').removeClass("active")
				$('#bread_3').addClass("checked selectable")
				$('#bread_2').addClass("active")
				$('#challengeIntro').removeClass("start-invis")
				// introJs().start('#challengeIntro')
				introJs().goToStep(1).start()		
		},2000);
	});	
}