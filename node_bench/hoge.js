
var os = require( 'os' );

function fib(n){
  if( n <= 0 ){
    return 1;
  }else{
    return fib(n-1) + fib(n-2);
  }
}

console.log( fib(40) );
  
