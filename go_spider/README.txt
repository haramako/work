# go-spider

- DBにキャッシュ情報を入れる
- キャッシュはファイルにそのまま
- HTTP(s)で直接キャッシュにアクセスできる(URL,キャッシュID両方)


- メッセージキューにタスクを入れられる
  - メッセージキューには、ダウンロードするURL,タスクの種類、引数など

MQ -- gospider  --GRPC-- worker
MySQL --+  |                |
           |                |
           +--    File  ----+


      gospider  ---MQ--- worker
MySQL --+  |                |
           |                |
           +--    File  ----+


- Job
 - key(MQのチャンネル?)
 - 入力URL[]
|
v
JobResult
 - URLの内容[]
 => 出力URL[]
