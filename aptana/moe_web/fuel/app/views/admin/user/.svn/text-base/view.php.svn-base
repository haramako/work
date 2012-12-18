<div class="row">
  <div class="span12">
	<h1>ユーザーの詳細</h1>

	<table class="table table-separated">
	  <tr>
		<th class="span2">ID</th>
		<td><?= $user->id ?></td>
	  </tr>
	  <tr>
		<th>プラットフォーム</th>
		<td><?= $user->platform ?></td>
	  </tr>
	  <tr>
		<th>UIID</th>
		<td><?= $user->uiid ?></td>
	  </tr>
	  <tr>
		<th>Pushトークン</th>
		<td class="wordbreak"><pre><?= $user->push_token ?></pre></td>
	  </tr>
	  <tr>
		<th>オプション</th>
		<td><?= json_encode( $user->option ) ?></td>
	  </tr>
	  <tr>
		<th>最終更新日</th>
		<td><?= Helper::datetime2str( $user->updated_at ) ?></td>
	  </tr>
	  <tr>
		<th>作成日</th>
		<td><?= Helper::datetime2str( $user->created_at ) ?></td>
	  </tr>
	</table>

	<div>
	  <?= Html::anchor( 'login?uiid='.$user->uiid, 'このユーザーでログインする', array( 'class'=>'btn' ) ) ?>
	</div>
  </div>
</div>
