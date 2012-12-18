<script>
$( function(){
  // 更新ボタンを押した時の処理
  $('.btn-update').live( 'click', function(e){
    var id = $(e.target).data('id');
    var tr = $('tr[data-id='+id+']');
    var val = $( '#val', tr ).val();
    var key = $( '#key', tr ).text();
    tr.load( APPROOT+'admin/kvs/ajax_update/'+id+' td', {val:val}, function(){
      flash( 'success', key+' を変更しました' );
    });
  });

  // 削除ボタンを押した時の処理
  $('.btn-delete').live( 'click', function(e){
    if( confirm( '削除します。よろしいですか？' ) ){
      var id = $(e.target).data('id');
      var tr = $('tr[data-id='+id+']');
      var key = $( '#key', tr ).text();
      tr.load( APPROOT+'admin/kvs/ajax_delete/'+id, function(){
        flash( 'danger', key+' を削除しました' );
      });
    }
  });

});
</script>

<div class="row">
  <div class="span12">
	<h1>設定一覧</h1>

	<?= Form::open( array( 'action'=>'admin/kvs', 'method'=>'GET', 'class'=>'well' )) ?>
		<span class="input-prepend">
		  <span class="add-on"><i class="icon-search"></i></span><?= Form::input( 'text', $text, array('placeholder'=>'検索') ) ?> 
		</span>
		<?= Form::submit(null,'検索',array('class'=>'btn btn-primary')) ?>
	<?= Form::close() ?>

	<table class="table table-striped table-bordered autopagerize_page_element">
	  <thead>
		<tr>
		  <th width="60">キー</th>
		  <th width="280">値</th>
		  <th>説明</th>
		  <th width="80">更新日</th>
		</tr>
	  </thead>
	  <tbody>
		<? foreach( $rows as $i=>$row ){ ?>
		  <?= View::forge( 'admin/kvs/_item', array( 'row'=>$row ) ) ?>
		<? } ?>
	  </tbody>
	</table>
	
	<?= Helper::pagination( $base_url, $page, $max_page ); ?>
	
  </div>
</div>
