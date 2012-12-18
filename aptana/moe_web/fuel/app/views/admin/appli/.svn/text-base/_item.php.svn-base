<td><?= $appli->platform[0] ?></td>
<td><img class="mini-icon" src="<?=$appli->icon?>" /></td>
<td>
  <a href="#" class="label appli-status <?=$appli->status_label()?>" data-status="<?=$appli->status?>"><?=$appli->status_str()?></a>
</td>
<td><?= Helper::truncate( $appli->title, 20 ) ?></td>
<td><?= Helper::truncate( $appli->description, 20 ) ?></td>
<td><?= Helper::date2str( $appli->created_at ) ?></td>
<td>
  <?= Html::anchor('admin/appli/view/'.$appli->id, '表示'); ?> |
  <?= Html::anchor('appli/view/'.$appli->id, 'プレ'); ?> |
  <?= Html::anchor('https://play.google.com/store/apps/details?id='.$appli->original_id, 'ストア'); ?>
</td>
