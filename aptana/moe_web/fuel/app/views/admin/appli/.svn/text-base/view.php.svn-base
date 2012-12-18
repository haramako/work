<style>
.legend { background-color: #ddd; border-radius: 4px; border: solid 1px #aaa; margin-left: 18px; text-align: center; }
.value-center { text-align: center; }
.row { padding-bottom: 12px; }
.img60 { max-width: 60px; max-height: 60px; }
</style>
<div class="row">
  <div class="span12">
	<h1><?= $appli->title ?>の詳細</h1>

	<table class="table table-striped">
	  <tr>
		<td class="span2">ID</td>
		<td><?= $appli->id ?></td>
	  </tr>
	  <tr>
		<td>Platform</td>
		<td ><?= $appli->platform ?></td>
	  </tr>
	  <tr>
		<td>タイトル</td>
		<td><?= $appli->title ?></td>
	  </tr>
	  <tr>
		<td>オリジナルID</td>
		<td><?= $appli->original_id ?></td>
	  </tr>
	  <tr>
		<td>カテゴリ</td>
		<td><?= $appli->category ?></td>
	  </tr>
	  <tr>
		<td>Author</td>
		<td><?= $appli->author ?></td>
	  </tr>
	  <tr>
		<td>値段</td>
		<td ><?= $appli->price ?></td>
	  </tr>
	  <tr>
		<td>レート</td>
		<td ><?= $appli->rate ?></td>
	  </tr>
	  <tr>
		<td>リリース日</td>
		<td ><?= Helper::date2str( $appli->release_date ) ?></td>
	  </tr>
	  <tr>
		<td>更新日</td>
		<td ><?= Helper::date2str( $appli->updated_at ) ?></td>
	  </tr>
	  <tr>
		<td>作成日</td>
		<td ><?= Helper::date2str( $appli->created_at ) ?></td>
	  </tr>
	  <tr>
		<td>状態</td>
		<td ><?= $appli->status ?></td>
	  </tr>
	  <tr>
		<td>萌え</td>
		<td ><?= $appli->moe ?></td>
	  </tr>
	  <tr>
		<td>ページビュー</td>
		<td ><?= $appli->view ?></td>
	  </tr>
	  <tr>
		<td>インストール数</td>
		<td ><?= $appli->install ?></td>
	  </tr>
	  <tr>
		<td>アイコン</td>
		<td><?= Html::img( $appli->icon, array( 'class'=>'img60' ) ) ?></td>
	  </tr>
	  <tr>
		<td>スクリーンショット</td>
		<td>
		<? foreach( $appli->screenshot as $screenshot ){ ?>
		  <?= Html::img( $screenshot, array( 'class'=>'img60' ) ) ?>
		<? } ?>
		</td>
	  </tr>
	</table>
	
	<h2>説明</h2>
	<pre><?php echo $appli->description; ?></pre>
	
	<h2>マッチしたキーワード</h2>
	<p><?= $match ?></p>

  </td>
</td>
