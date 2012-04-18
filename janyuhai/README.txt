*雀友牌のサーバー/クライアントソースコード

**コーディング規約

***命名規則

基本的な coffee-script( javascript )の命名規則に従う

システムハンガリアンとして、下記のハンガリアンを使用する。
（これは、PaiIdとPaiKindはともに整数なので、区別がつきにくいため）
- PaiId: pi
- PaiKind: pk

***パッケージ

パッケージのファイルの頭には下記のコードを入れること。
これは、ブラウザとnodejsのパッケージシステムの違いを吸収する役割がある。

 # nodeとブラウザの両対応用, nodeの場合はそのままで,ブラウザの場合はwindowをexportsとする
 if typeof(module) == 'undefined' and typeof(exports) == 'undefined'
     eval('var exports, global; exports = {}; window.（パッケージ名） = exports; global = window;')


*必要なnpmパッケージ

- coffee-script
- gzip
- libxmljs        XMLパーサー,天鳳ファイルのパースで使用
- msgpack2
- optparse
- underscore
- vows            テストフレームワーク


