<!-- obj_image.php -->
<li class="object_vertical <?= $app->info['position'] ?>">
  <div class="app_evaluation_area">
	<?= Html::img( "assets/img/btn_moe_off.png", array( 'class'=>'moe_button', 'data-id'=>$app->id ) ) ?>
    <?= Html::img( "assets/img/rating_{$app->info['moe_star']}.png", array('class'=>'moe_count') ) ?> 
  </div>

  <div class="app_thumbnail_area">
	<div class="img_frame">
	  <a href="id001">
		<?= Html::anchor( 'appli/view/'.$app->id, Html::img( $app->info['screenshot'], array( 'class'=>"timeline_template_photo_img", 'width'=>260, 'height'=>$app->info['screenshot_height'] ) ) ) ?>
	  </a>
	</div>
  </div>

  <div class="app_info_area">
	<div class="app_name">
      <?= $app->title ?>
	</div>
	<div class="app_category">
      <?= $app->category ?>
	</div>
  </div>

  <div class="ico_sider_l">
	<div class="timeline_v_plate"></div>
	<?= Html::img( 'assets/img/badge_rank_'.$app->info['top_class'].'.png', array('class'=>'timeline_badge') ) ?>
	<span class="ranking_num <?=$app->info['ranking_num_class']?>"><?= $app->info['rank'] ?></span>
  </div>
</li>
<!-- /obj_image.php -->
