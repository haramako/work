Pandora  - A Storage Engine for Unity Games -
====

## Description/概要

Pandora はUnity向けのゲームのセーブデータの保存に最適化したストレージエンジンです。

Unityでの利用を想定していますが、Pure C# で記述されていますので、Unityに限らずどこでも利用可能です。

下記のような利点を持っています。

- 高速
- あらゆるプラットフォームで動く
- 頻繁に更新されるデータに最適


また、下記の特徴を持っています。

- KVSインターフェース
- Pure C#
- インメモリですべてのデータを保持
- ヒストリにアクセスできる
- データの破壊/改竄に強い
- クラウドにバックアップ/同期(オプショナル)

## ToC

- Requrement
- Install
- 使い方
- 利点
- ストレージ
  - メモリストレージ
  - ファイルストレージ
- クラウド同期について
- 詳細
  - ファイルフォーマット
  - クラウドプロトコル
  - 破壊時のリカバリ

## Requirement

## Install

    $ nuget install pandora


## Usage/使い方

メモリストレージに値を保存する

```
using Pandora;

var cabinet = new Cabinet(); // データベースを作成する

cabinet.Put("hoge", "fuga"); // キーと値を指定して、レコードを保存する

cabinet.Put(0x00112233, new byte[]{1,2,3}); // キーは64bit, 値は byte[] がネイティブデータ

var data = cabinet.Get("hoge"); // レコードの値の取得

cabinet.Delete("hoge"); // レコードの削除

cabinet.Exists("hoge"); // レコードが存在するかの確認

cabinet.Commit();

byte[] saveData = cabinet.Dump(); // セーブデータはbyte[]で取り出せるので、これを必要に応じて保存する
```


ファイルストレージで利用する

```
// パスを指定して、データベースを作成する
var storage = new FileStorage("./path_to_save.db");
var cabinet = new Cabinet(storage);
...

cabinet.Commit(); // ファイルの場合は、Commit()するたびにファイルに追記で保存される
```

## ストレージ

### メモリ・ストレージ

データはインメモリで処理され、`Dump()` で byte[]として取り出すことができます。

これは、ゲームコンソールでは、ファイルの追記などは対応せず、ファイル全体単位でしか書き換えられないことが多いためです。


### ファイルストレージ

データは、`Commit()`されるたびに、ファイルに追記で保存されます。

変更部分だけ追記されるので、変更が少なければ、とても高速です。また、書き込み失敗時にもセーブデータの破壊される恐れがなく、リカバリが可能です。



## Contribution

## Licence

[MIT](https://github.com/tcnksm/tool/blob/master/LICENCE)

## Author

[haramako](https://github.com/haramako)

