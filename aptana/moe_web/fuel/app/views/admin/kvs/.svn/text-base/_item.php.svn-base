<tr data-id="<?= $row['id'] ?>">
  <td id="key"><?= $row['key'] ?></td>
  <td>
	<div class="input-append">
	  <?= Form::input( 'val',  $row['val'], array( 'id'=>'val', 'class'=>'span3') ) ?><button class="btn btn-update" type="button" data-id="<?= $row['id'] ?>">更新</button>
	  <!-- <a class="btn btn-danger btn-delete" data-id="<?= $row['id']?>">削除</a> -->
	</div>
  </td>
  <td><?= $row['desc'] ?></td>
  <td><?= Helper::date2str( $row['updated_at'] ) ?></td>
</tr>
