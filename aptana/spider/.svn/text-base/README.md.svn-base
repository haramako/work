
spider: もプリたん アプリクローラ
==============

もプリたんの app store/google play クローラのレポジトリです


初期設定
---------------

1. `$ cd tool/animeface; make` でanimeface(顔認識プログラム)をビルドします。

2. mysqlでデータベースを作成します( `$ mysql -u root -e 'create database spider'` )

3. DBの設定をします( `cp fuel/app/config/development/db.php.sample fuel/app/config/development/db.php` その後、db.phpを編集)

4. DBの初期化をします( `$ oil refine migrate` )

5. .htaccessをコピーします( `$ cp public/.htaccess.sample public/.htaccess` )

6. `public/.htaccess`を編集( RewriteBaseの追加など )

7. `http://(ルートパス)/admin/` で管理画面にブラウザでアクセスできます


クローラの動かし方
----------------

`$ oil refine spider` でシングルスレッドでクローラを起動します。

`$ oil refine spider:multi 32` で３２個のクローラを並列で実行します（数は変更可能)

`$ oil refine spider:help` でその他のオプションを確認できます。


ディレクトリ構造
----------------

標準的なFuelPHPの構成ですが、WEB以外のシステムのディレクトリを下記で説明します。

<pre>
.
├── README.md
├── fuel
│   ├── LICENSE
│   ├── app
│   │   ├── cache
│   │   ├── classes
│   │   │   ├── controller
│   │   │   ├── model
│   │   │   ├── view
│   │   │   └── spider        spider関係のクラス
│   │   ├── config
│   │   │   ├── development
│   │   │   └── production
│   │   ├── lang
│   │   ├── logs
│   │   ├── migrations
│   │   ├── modules
│   │   ├── tasks
│   │   │   └── spider.php    spiderのタスク
│   │   ├── tmp
│   │   └── vendor
│   │        └── phpQuery      phpQuery (jQueryライクなDOM操作ライブラリ、spiderで使用)
│   ├── core
│   └── packages
├── oil
├── tool
│   └── animeface               萌え絵判定用のプログラム(opencv使用)
└── public
     ├── assets
     │   ├── css
     │   ├── img
     │   └── js
     └── index.php
</pre>
