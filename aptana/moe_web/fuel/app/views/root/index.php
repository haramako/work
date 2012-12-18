<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
</head>
<body>
  <p><?= Html::anchor('/latest/all', '最新/すべて' ) ?></p>
  <p><?= Html::anchor('/latest/free', '最新/無料' ) ?></p>
  <p><?= Html::anchor('/latest/paid', '最新/有料' ) ?></p>
  <p><?= Html::anchor('/ranking/popular', 'ランキング/人気' ) ?></p>
  <p><?= Html::anchor('/ranking/moe', 'タイムライン/萌え!' ) ?></p>
  <p><?= Html::anchor('/mymoe', 'マイ萌えアプリ' ) ?></p>
  <br/>
  <p><?= Html::anchor('/login?uiid=1', 'ログインテスト(ios)' ) ?></p>
  <p><?= Html::anchor('/login?uiid=2', 'ログインテスト(android)' ) ?></p>
  <br/>
  <p><?= Html::anchor('/admin', '管理画面' ) ?></p>
  </pre>
</body>
</html>

