<!-- obj_portrait.php -->
<li class="object_horizontal">
  <div class="app_thumbnail_area">
	<div class="img_frame">
	  <?= Html::anchor( 'appli/view/'.$app->id, Html::img( $app->info['screenshot'], array( 'width'=>480, 'height'=>$app->info['screenshot_height'] ) ) ) ?>
	</div>
  </div>

  <div class="app_info_area">
	<div class="app_info_left">
	  <?= Html::img( "assets/img/btn_moe_off.png", array( 'class'=>'moe_button', 'data-id'=>$app->id ) ) ?>
      <?= Html::img( "assets/img/rating_{$app->info['moe_star']}.png", array('class'=>'moe_count') ) ?>
	</div>

	<div class="app_info_right">
	  <div class="app_name">
		<?= $app->title ?>
	  </div>
	  <div class="app_category">
		<?= $app->category ?>
	  </div>
	</div>
  </div>

  <div class="ico_sider_l">
	<div class="timeline_v_plate"></div>
	<?= Html::img( 'assets/img/timeline_circle_top_stop.png', array( 'class'=>'timeline_icon' ) ) ?>
  </div>
</li>
<!-- /obj_portrait.php -->
