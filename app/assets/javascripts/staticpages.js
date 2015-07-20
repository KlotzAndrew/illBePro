
var page_faq_toggles = function(){
	$('#toggle_faq_setup').on("click", function(){
		$('#faq_setup').toggleClass("start-ghost")
		$('#toggle_faq_setup_arrow').toggleClass("fa-arrow-right")
		$('#toggle_faq_setup_arrow').toggleClass("fa-arrow-down")
	})
	$('#toggle_faq_challenges').on("click", function(){
		$('#faq_challenges').toggleClass("start-ghost")
		$('#toggle_faq_challenges_arrow').toggleClass("fa-arrow-right")
		$('#toggle_faq_challenges_arrow').toggleClass("fa-arrow-down")
	})	
	$('#toggle_faq_prizes').on("click", function(){
		$('#faq_prizes').toggleClass("start-ghost")
		$('#toggle_faq_prizes_arrow').toggleClass("fa-arrow-right")
		$('#toggle_faq_prizes_arrow').toggleClass("fa-arrow-down")		
	})		
}

var carosele_indicators = function(){
	$('.breadcrumb').hover(function(){
		$(this).toggleClass("active")
	})
}

var is_page_landing_page = function(){ // also runs static pages
    console.log("landing_page setup running")
    current_page = $('#page_name').data("pagespec")    
  if (current_page == "landing_page") {
		console.log("this is landing_page")
		carosele_indicators()
    } else {
      console.log("this is not landing_page");
    } 

   if (current_page == "static_page"){
   	page_faq_toggles();
   }
}

$(window).unload(function(){
})