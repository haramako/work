<?= Asset::css( 'appli.css' ) ?>

<? if( $app->status != 'K' ){ ?>

<ul id="main">
  <li id="appinfo">
	<div id="app_icon">
	  <div class="icon_frame">
		<?= Html::img( $app->icon ) ?>
	  </div>
	</div>

	<div id="body">
	  <div id="app_category"><?= $app->category ?></div>
	  <div id="app_name"><?= $app->title ?></div>
	  <div id="app_price"><? if( $app->price != 0 ){ echo '￥'.$app->price; }else{ echo '無料'; } ?></div>
	  
	</div>

	<div id="moe_button">
	  <?= Html::img( "assets/img/btn_moe_off.png", array('class'=>'moe_button', 'data-id'=>$app->id ) ) ?>
	  <div class="moe_count">
		<span class="moe_count_num"><?= $app->moe ?></span> 萌え
	  </div>
	</div>
	  <div id="app_download">
		<?= Html::anchor( 'appli/install/'.$app->id, Html::img( "assets/img/appli/btn_install_on.png", array( 'class'=>'download_button' ) ) ) ?>
		</a>
	  </div>
  </li>
  <? if( $app->screenshot ){ ?>
  <li id="thumbnail">
	<a href="<?=Uri::base()?>appli/screenshot/<?=$app->id?>">
	  <div class="thumbnail-cover"></div>
	  <? foreach( $app->screenshot as $i=>$image ){ ?>
	    <? if( $app->platform == 'android' ){ ?>
	      <?= Html::img( preg_replace( '/=.+$/','=h200', $image ), array( 'class'=>'screenshot' ) ) ?>
		<? }else{ ?>
	      <?= Html::img( $image, array( 'class'=>'screenshot' ) ) ?>
	    <? } ?>
	  <? } ?>
	</a>
  </li>
  <? } ?>
  <li id="description">
	<ul>
	  <li id="title_img">
		<?= Html::img( "assets/img/appli/description_icon.png" ) ?><br/>
		説明
	  </li>
	  <li id="body">
		<?= str_replace( "\n", '<br/>', $app->description ) ?>
	  </li>
	</ul>
  </li>
</ul>

<? }else{ ?>
  <!-- すでに削除されている場合 -->
  <ul id="main">
    <li id="appinfo">
  	  このアプリにはアクセスできません。すでにストアから削除されている可能性があります。
    </li>
  </li>
<? } ?>
