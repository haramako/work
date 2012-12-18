$( function(){
	$('.togglable').live( 'click', function(e){
		var span = $(e.currentTarget);
		var id = span.data('id');
		var val = span.data('val');
		var new_val = {D:'', '':'D'}[val];
		$.get( APPROOT+'admin/appli/change_status/'+id+'?val='+new_val, function(){
			if( new_val == 'D' ){
				span.text( '削除' ).addClass('label-warning').data('val', 'D');
			}else{
				span.text( '通常' ).removeClass('label-warning').data('val', '');
			}
		});
	});
});
