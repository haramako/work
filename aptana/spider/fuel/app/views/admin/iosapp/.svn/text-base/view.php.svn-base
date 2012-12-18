<div class="row">
  <div class="span12">
	<h1>
	  <img src="<?= $app['artwork_url60'] ?>" />
	  <?= $app['track_name'] ?>　
	  <a class="btn btn-info" href="<?= $app['track_view_url'] ?>">App Storeで表示</a></h1>
  </div>
</div>

<div class="row">
  <div class="span8">
	<table class="table">
	  <tr>
		<th width="80">ID</th>
		<td><?= $app['id'] ?></td>
	  </tr>
	  <tr>
		<th width="80">App Store ID</th>
		<td><?= $app['track_id'] ?></td>
	  </tr>
	  <tr>
		<th>ジャンル</th>
		<td><?= $app['genres'] ?></td>
	  </tr>
	  <tr>
		<th>値段</th>
		<td><?= (int)$app['price'] ?></td>
	  </tr>
	  <tr>
		<th>販売元</th>
		<td><?= $app['artist_name'] ?></td>
	  </tr>
	  <tr>
		<th>リリース日</th>
		<td><?= $app['release_date'] ?></td>
	  </tr>
	  <tr>
		<th>説明</th>
		<td><?= str_replace( "\n", '<br/>', $app['description'] ) ?></td>
	  </tr>
	</table>
	<h3>全データ</h3>
	<pre><?= print_r( $app, true ) ?></pre>
  </div>
  <div class="span4">
	<h3>アイコン</h3>
	<p><img src="<?= $app['artwork_url512'] ?>"/></p>
	<h3>スクリーンショット</h3>
	<? foreach( $app['screenshot_urls'] as $img ){ ?>
	  <p><img src="<?= $img ?>"/></p>
	<? } ?>
  </div>
</div>
