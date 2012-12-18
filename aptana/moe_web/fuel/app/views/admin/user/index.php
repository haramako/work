
<div class="row">
  <div class="span12">
	<h1>ユーザー一覧</h2>

	<?= Form::open( array( 'action'=>'admin/user', 'method'=>'GET', 'class'=>'well' )) ?>
      <span class="input-prepend">
		<span class="add-on"><i class="icon-search"></i></span><?= Form::input( 'text', $text ) ?> 
      </span>
	  <?= Form::submit(null,'検索', array( 'class'=>'btn btn-primary' ) ) ?>
	<?= Form::close() ?>
	
	<? if( $users ){ ?>
	
	  <table class="table table-striped table-bordered autopagerize_page_element">
		<thead>
		  <tr>
			<th width="60">ID</th>
			<th width="60">Platform</th>
			<th width="100">UIID</th>
			<th>Push Token</th>
			<th>Debug</th>
			<th width="120">作成日</th>
			<th width="80"></th>
		  </tr>
		</thead>
		<tbody>
		  <? foreach( $users as $i=>$user ){ ?>
		  <tr>
			<td><?= $user->id ?></td>
			<td><?= $user->platform ?></td>
			<td><div style="overflow-x:hidden; white-space: nowrap; width:100px;"><?= $user->uiid ?></div></td>
			<td><div style="overflow-x:hidden; white-space: nowrap; width:200px;"><?= $user->push_token ?></div></td>
			<td><?= isset( $user->option->debug) && $user->option->debug ?></div></td>
			<td><?= date('Y-m-d H:i:s', $user->created_at ) ?></div></td>
			<td>
			  <?= Html::anchor( 'admin/user/view/'.$user->id, '詳細' ) ?> |
			  <?= Html::anchor( 'admin/user/delete/'.$user->id, '削除', array( 'onclick' => "return confirm('削除してよろしいですか？');" ) ) ?>
			</td>
		  </tr>
		  <? } ?>
		</tbody>
	  </table>
	  <?= Helper::pagination( $base_url, $page, $max_page ); ?>
	  
	<? }else{ ?>
	  ユーザーは、存在しません.
	<? } ?>
	
	
  </div>
</div>
