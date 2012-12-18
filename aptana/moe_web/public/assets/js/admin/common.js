$( function(){
	// フラッシュの表示
	function flash( type, text ){
		var box = $('<div class="alert alert-block"></div>')
				.addClass('alert-'+type)
				.text(text)
				.appendTo('#flash');
		box.delay(5000).animate({opacity:0}, 1000, function(){ box.remove(); } );

	}
	window.flash = flash;

});
