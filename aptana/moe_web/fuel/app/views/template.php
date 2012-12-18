<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="content-type" content="text/html;charset=UTF-8">
	<meta name="viewport" content="width=640px,target-densitydpi=320,initial-scale=1.0,user-scalable=no">
	<title><?= $title ?></title>
	<?= Asset::js('jquery.min.js') ?>
	<?= Asset::js('common.js') ?>
	<script type="text/javascript">var APPROOT = '<?= Uri::base() ?>';</script>
</head>
<body>
<?= $content ?>
</body>
</html>
