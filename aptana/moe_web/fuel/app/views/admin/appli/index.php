<script>
$( function(){
  $('.appli-status').live( 'click', function(e){
	var tr = $(e.target).parents('tr[data-id]');
    var id = tr.data('id');
    var status= $(e.target).data('status');
    var new_status = (status=='')?'D':'';
	tr.load( APPROOT+'admin/appli/ajax_update/'+id+'?status='+new_status );
	return false;
  });
});
</script>

<div class="row">
  <div class="span12">
	<h1>アプリの一覧</h1>

	<?= Form::open( array( 'action'=>'admin/appli', 'method'=>'GET', 'class'=>'well form-horizontal' )) ?>
	  <fieldset>
		<div class="control-group">
		  <label class="control-label" for="platform">プラットフォーム</label>
		  <div class="controls">
			<label class="radio inline"><?= Form::radio( 'platform', '', $platform=='' ) ?> 指定なし</label>
			<label class="radio inline"><?= Form::radio( 'platform', 'android', $platform=='android' ) ?> android</label>
			<label class="radio inline"><?= Form::radio( 'platform', 'ios', $platform=='ios' ) ?> ios</label>
		  </div>
		</div>
		<div class="control-group">
		  <label class="control-label" for="text">検索ワード</label>
		  <div class="controls">
			<span class="input-prepend">
			  <span class="add-on"><i class="icon-search"></i></span><?= Form::input( 'text', $text ) ?> 
			</span>
			※タイトルのみ
		  </div>
		</div>
		<div class="control-group">
		  <label class="control-label" for="">並び順</label>
		  <div class="controls">
			<?= Form::select( 'order_by', $order_by, array('id'=>'ID', 'updated_at'=>'更新日', 'release_date'=>'リリース日') ) ?>
		  </div>
		</div>
		<div class="control-group">
		  <label class="control-label" for="">その他</label>
		  <div class="controls">
			<label class="checkbox inline"><?= Form::checkbox( 'show_deleted', 'T', $show_deleted ) ?> 削除済みを表示</label>
		  </div>
		</div>
		<div class="form-actions">
          <button type="submit" class="btn btn-primary">検索</button>
        </div>
	  </fieldset>
	<?= Form::close() ?>
	
	<table class="table table-striped table-bordered autopagerize_page_element">
	  <thead>
		<tr>
		  <th>プ</th>
		  <th>Icon</th>
		  <th>状態</th>
		  <th>Title</th>
		  <th>Description</th>
		  <th>作成日</th>
		  <th></th>
		</tr>
	  </thead>
	  <tbody>
		<? foreach ($applis as $appli): ?>
		  <tr data-id="<?=$appli->id?>">
		    <?= View::forge( 'admin/appli/_item', array( 'appli'=>$appli ) ) ?>
		  </tr>
		<? endforeach ?>
	  </tbody>
	</table>

	<?= Helper::pagination( $base_url, $page, $max_page ); ?>
	
  </div>
</div>
