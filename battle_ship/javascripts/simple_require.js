/*
node.jsのｑrequireの真似をブラウザで行うためのコード.
対象パッケージのjsは事前に読み込んだ状態で、node.jsのrequireと同様に利用する。

使用例:
 
<script src="./underscore-min.js"></script>
<script src="./simple_require.js"></script>
<script src="./jan.js"></script>
 
<script>
function hoge(){
  var jan = require( 'jan' );
 
  ...janパッケージを利用したコード...
  console.log( jan.PaiId.MAX ); // 例
 
}
</script> 
 
*/
window.underscore = _; // underscore.jsは特別に登録する
function require(name){
  return window[name]; // 絶対パス
}
