
var previewSetupTimer;
var current_step = 1
var cycle_preview = true
var preview_steps_cycle = function(){
	if (cycle_preview == true) {
		if (current_step == 1) {
			preview_12();
		} else if (current_step == 2) {
			preview_23();
		} else if (current_step == 3) {
			preview_31();
		} else {
			console.log("unknown step")
		}
		if (cycle_preview == true) {
			var previewSetupTimer = setTimeout( preview_steps_cycle, 5000);		
		}
	}
}

var timeoutSlide1;
var preview_slide1 = function(){
	$('#lp-s1').show( "slide", { direction: "right" }, 2000 )
}

var timeoutSlide2;
var preview_slide2 = function(){
	$('#lp-s2').show( "slide", { direction: "right" }, 2000 )
}

var timeoutSlide3;
var preview_slide3 = function(){
	$('#lp-s3').show( "slide", { direction: "right" }, 2000 )
}

var preview_12 = function(){
	no_click_while_sliding();
	$('#bread_1').removeClass("active")
	$('#bread_1').addClass("checked selectable")
	$('#bread_2').addClass("active")

	$('#lp-s1').hide( "slide", { direction: "left" }, 2000 );

	var timeoutSlide2 = setTimeout( preview_slide2, 2000);

	current_step += 1
};

var preview_23 = function(){
	no_click_while_sliding();
	$('#bread_2').removeClass("active")
	$('#bread_2').addClass("checked selectable")
	$('#bread_3').addClass("active")
	
	$('#lp-s2').hide( "slide", { direction: "left" }, 2000 );
	var timeoutSlide3 = setTimeout( preview_slide3, 2000);

	current_step += 1			
};

var preview_31 = function(){
	no_click_while_sliding();
	$('#bread_3').removeClass("active")
	$('#bread_2').removeClass("checked selectable")
	$('#bread_1').removeClass("checked selectable")
	$('#bread_1').addClass("active")

	$('#lp-s3').hide( "slide", { direction: "left" }, 2000 );

	var timeoutSlide1 = setTimeout( preview_slide1, 2000);
	current_step = 1			
};

var preview_1 = function(){
	no_click_while_sliding();
	if (current_step == 2) {
		$('#lp-s2').hide( "slide", { direction: "left" }, 2000 );
	} else if ( current_step == 3) {
		$('#lp-s3').hide( "slide", { direction: "left" }, 2000 );
	} else {}

	var timeoutSlide1 = setTimeout( preview_slide1, 2000);

	$('#bread_1').addClass("active")
	$('#bread_1').removeClass("checked selectable")

	$('#bread_2').removeClass("active")
	$('#bread_2').removeClass("checked selectable")

	$('#bread_3').removeClass("active")
};

var preview_2 = function(){
	no_click_while_sliding();
	if ( current_step == 1) {
		$('#lp-s1').hide( "slide", { direction: "left" }, 2000 );
	} else if ( current_step == 3 ) {
		$('#lp-s3').hide( "slide", { direction: "left" }, 2000 );
	} else {}

	var timeoutSlide2 = setTimeout( preview_slide2, 2000);

	$('#bread_1').addClass("checked selectable")
	$('#bread_1').removeClass("active")

	$('#bread_2').addClass("active")
	$('#bread_2').removeClass("checked selectable")

	$('#bread_3').removeClass("active")
};

var preview_3 = function(){
	no_click_while_sliding();
	if (current_step == 1) {
		$('#lp-s1').hide( "slide", { direction: "left" }, 2000 );
	} else if ( current_step == 2 ) {
		$('#lp-s2').hide( "slide", { direction: "left" }, 2000 );
	} else {}

	var timeoutSlide3 = setTimeout( preview_slide3, 2000);

	$('#bread_1').addClass("checked selectable")
	$('#bread_1').removeClass("active")

	$('#bread_2').addClass("checked selectable")
	$('#bread_2').removeClass("active")

	$('#bread_3').addClass("active")
};

var clear_preview_timeouts = function(){
	clearTimeout(preview_1);
	clearTimeout(preview_2);
	clearTimeout(preview_3);
}

var can_slide = true
var no_click_while_sliding = function(){
	if (can_slide == true) {
		can_slide = false;
		setTimeout(function(){
			can_slide = true;
		}, 4000)
	}
}


var stop_setup_preview = function(){
    $('#bread_1').on("click", function(){
        clearTimeout(previewSetupTimer)
        cycle_preview = false
        if (can_slide == true) {
	        if (current_step == 1) {      	
	        } else {
	        	clear_preview_timeouts();
	        	preview_1();
	        	current_step = 1
	        }
        }
    })
    $('#bread_2').on("click", function(){
        clearTimeout(previewSetupTimer)
        cycle_preview = false
        if (can_slide == true) {
	        if (current_step == 2) {      	
	        } else {
	        	clear_preview_timeouts();
	        	preview_2();
	        	current_step = 2
	        }        
        }
    })	
    $('#bread_3').on("click", function(){
        clearTimeout(previewSetupTimer)
        cycle_preview = false
        if (can_slide == true) {
	        if (current_step == 3) {      	
	        } else{
	        	clear_preview_timeouts();
	        	preview_3();
	        	current_step = 3
	        }        
        }
    })	
};

var is_page_landing_page = function(){
    console.log("landing_page setup running") 
    current_page = $('#page_name').data("pagespec")    
  if (current_page == "landing_page") {
		console.log("this is landing_page")
		stop_setup_preview();
		var previewSetupTimer = setTimeout( preview_steps_cycle, 5000);
    } else {
      console.log("this is not landing_page");
    }  
}


$(window).unload(function(){
  clearTimeout(previewSetupTimer)
})