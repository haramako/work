<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="content-type" content="text/html;charset=UTF-8">
	<meta name="viewport" content="width=640, target-densitydpi=320,user-scalable=no">
	<?= Asset::css('bootstrap.min.css') ?>
	<?= Asset::css('admin/common.css') ?>
	<?= Asset::js('jquery.min.js') ?>
	<?= Asset::js('admin/common.js') ?>
	<script type="text/javascript">var APPROOT = '<?= Uri::base() ?>';</script>
	<title><?= $title ?> (<?= Fuel::$env ?>)</title>
	<style>
	  <? if( Fuel::$env == Fuel::PRODUCTION ){ ?> 
	    .navbar-inner { box-shadow: 0 -8px 16px rgba(255,0,0,1.0) inset !important; } /* 本番環境では赤く */
	  <? } ?>
	</style>
</head>
<body>
  <div class="navbar navbar-fixed-top">
	<div class="navbar-inner">
	  <div class="container">
		<?= Html::anchor( 'admin', 'もプリたん管理ツール('.Fuel::$env.')', array( 'class'=>'brand' ) ) ?>
		<div class="nav-collapse collapse">
		  <ul class="nav">
			<li><?= Html::anchor( 'admin/user', 'ユーザー' ) ?></li>
			<li><?= Html::anchor( 'admin/appli', 'アプリ' ) ?></li>
			<li><?= Html::anchor( 'admin/kvs', '設定' ) ?></li>
			<li><?= Html::anchor( 'admin/statistics', '統計' ) ?></li>
		  </ul>
		</div>
	  </div>
	</div>
  </div>
  <div class="container" style="margin-top:40px;">
    <div class="span12" id="flash">
    </div>
	<?= $content ?>
  </div>
</body>
</html>
