$( function(){

	// 萌えボタンの押された時の処理
	// document.onclickをcaptureして、全部のimg.moe_buttonのクリックイベントを取る
	document.addEventListener( 'click', function(e){
		// 萌えボタンじゃないなら素通り
		if( ! $(e.srcElement).hasClass('moe_button') ) return true;
		
		var id = $( e.srcElement ).data('id');

		// 通信処理
		$.get( APPROOT+'appli/moe/'+id+'?dummy='+Date.now(), function( text ){
			// 萌えカウントの増加
			var count = $('.moe_count_num');
			count.text( parseInt(count.text(),10)+1 );
		} );

		// 萌えボタンのアニメーション
		var src = $(e.srcElement); // 押された萌えボタン
		/*
		var img = $('<img>'); // アニメーションノード
		img.attr('src',e.srcElement.src)
				.addClass('moe_button_anim')
				.css(src.offset())
				.animate({top: src.offset().top-40, opacity: 0 },1000,
						 function(){ img.remove(); } )
				.appendTo($('body'));
		*/
		var count = 0;
		var animate = function(){
			if( count % 2 == 0 ){
				src.attr( 'src', APPROOT+'assets/img/btn_moe_off.png' );
			}else{
				src.attr( 'src', APPROOT+'assets/img/btn_moe_on.png' );
			}
			if( count < 6 ) setTimeout( animate, 200 );
			count++;
		};
		setTimeout( animate );
		
		return false;
	}, true );
	
	// 「次の２５件を取得する」の初期化
	if( $.autopager ){
		$.autopager({content:'#timeline_object', link:'a[rel=next]', autoLoad:true });
		$('.timeline_pagerize').click( function(){
			$.autopager('load');
			return false;
		} );
	}
});
