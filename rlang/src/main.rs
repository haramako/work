extern crate rlang;

use rlang::codegen;
use rlang::parser;

fn main() {
    let src = "func hoge(a:int b:int):int { var a:int = 123; return a + b; }";
    let prog = parser::parse(src);
    println!("{:?}", prog);

    let code = codegen::gencode(&prog.unwrap()).unwrap();
    codegen::dump(&code)
}
