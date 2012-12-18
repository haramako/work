<?= Asset::css('timeline.css') ?>
<?= Asset::js('jquery.autopager.min.js') ?>

<div id="center_line">
  <ul id="timeline_object" class="timeline_page_cont">
	 <? $i=-1; foreach( $apps as $app ){ $i+=1;?>
       <?= View::forge('latest/obj_'.$app->info['style'], array( 'app'=>$app ) ) ?>
	<? } ?>
  </ul>
</div>

<? if( count($apps) >= 20 ){ ?>
<div class="timeline_pagerize">
  <?= Html::anchor( $base.($page+1), '次の２０件', array( 'rel'=>"next" ) ) ?>
</div>
<? } ?>

<script><? if( isset($loaded_script) ){ echo $loaded_script; } ?></script>  
