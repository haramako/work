
<div class="row">
  <div class="span12">
	<h2>Google Play アプリ一覧</h2>

	<?= Form::open( array( 'action'=>'admin/androidapp', 'method'=>'GET', 'class'=>'well' )) ?>
		<?= Form::checkbox( 'is_japanese', 1, $filter_is_japanese ) ?> 日本語　
		<?= Form::checkbox( 'has_face', 1, $filter_has_face ) ?> 顔認識　
		<span class="input-prepend">
		  <span class="add-on"><i class="icon-search"></i></span><?= Form::input( 'text', $filter_text, array('placeholder'=>'検索') ) ?> 
		</span>
		並び順:<?= Form::select( 'order_by', $order_by, array('release_date'=>'リリース日','id'=>'id'), array( 'class'=>'span2' ) ) ?>
		<?= Form::submit(null,'検索') ?>
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
		  <td><img class="mini-icon" src="<?= $app['icon'] ?>" /></td>
		  <td><?= Helper::bool2icon( $app['has_face'] ) ?></td>
		  <td><?= Helper::bool2icon( $app['is_japanese'] ) ?></td>
		  <td><?= Html::anchor( 'admin/androidapp/view/'.$app['id'], mb_substr($app['title'],0,20) ) ?></td>
		  <td><?= mb_substr( $app['description'], 0, 25 ) ?></td>
		  <td><?= $app['release_date'] ?></td>
		</tr>
		<? } ?>
	  </tbody>
	</table>
	
	<?= Helper::pagination( $base_url, $page, $max_page ); ?>
	
  </div>
</div>
