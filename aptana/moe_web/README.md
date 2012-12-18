
もプリたん WEB
==============

もプリたんのアプリからアクセスされるWEBです。


動かし方(web)
---------------

通常のFuelPHPの初期設定と同様です。

1. 依存するモジュールをインストールします( 下記はubuntuの場合の一例 )
   <pre>
   $ sudo apt-get install openssl      # openssl のインストール
   $ sudo apt-get install php-pear     # pear のインストール
   $ sudo pear install HTTP_Request2   # HTTP_Request2のインストール
   </pre>

2. mysqlでデータベースを作成します
   <pre>$ mysql -u root -e 'create database moe' </pre>

3. 下記のファイルを '.sample' がついたファイルからコピーし、編集します
   - fuel/app/config/development/db.php
   - fuel/app/config/development/config.php
   - public/.htaccess

4. DBの初期化をします
   <pre>$ oil refine migrate </pre>



ディレクトリ構造
----------------

標準的なFuelPHPの構成です。

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
│   │   │   └── spider
│   │   ├── config
│   │   │   ├── development
│   │   │   └── production
│   │   ├── lang
│   │   ├── logs
│   │   ├── migrations
│   │   ├── modules
│   │   ├── tasks
│   │   │   └── spider.php
│   │   ├── tmp
│   │   └── vendor
│   ├── core
│   └── packages
├── oil
└── public
     ├── assets
     │   ├── css
     │   ├── img
     │   └── js
     └── index.php
</pre>
