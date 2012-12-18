<div class="row">
  <div class="span12">
	<h2>App Store アプリ一覧</h2>

	<?= Form::open( array( 'action'=>'admin/iosapp', 'method'=>'GET' )) ?>
	  <?= Form::checkbox( 'has_face', 1, $filter_has_face ) ?> 顔認識
	  <?= Form::checkbox( 'is_japanese', 1, $filter_is_japanese ) ?> 日本語
      <span class="input-prepend">
		<span class="add-on"><i class="icon-search"></i></span><?= Form::input( 'text', $filter_text ) ?> 
      </span>
	  <?= Form::submit('') ?>
	<?= Form::close() ?>

	<?= Helper::pagination( $base_url, $page, $max_page ); ?>
	
	<table class="table table-striped table-bordered autopagerize_page_element">
	  <thead>
		<tr>
		  <th width="60">ID</th>
		  <th width="30">Icon</th>
		  <th width="20">顔</th>
		  <th width="20">日</th>
		  <th>タイトル</th>
		  <th>説明</th>
		  <th>リリース日</th>
		</tr>
	  </thead>
	  <tbody>
		<? foreach( $apps as $i=>$app ){ ?>
		<tr>
		  <td><?= $app['id'] ?></td>
		  <td><img class="mini-icon" src="<?= $app['artwork_url60'] ?>" /></td>
		  <td><?= Helper::bool2icon( $app['has_face'] ) ?></td>
		  <td><?= Helper::bool2icon( $app['is_japanese'] ) ?></td>
		  <td><?= Html::anchor( 'admin/iosapp/view/'.$app['id'], mb_substr($app['track_name'],0,20) ) ?></td>
		  <td><?= mb_substr( $app['description'], 0, 25 ) ?></td>
		  <td><?= $app['release_date'] ?></td>
		</tr>
		<? } ?>
	  </tbody>
	</table>
	
	<?= Helper::pagination( $base_url, $page, $max_page ); ?>
	
  </div>
</div>
