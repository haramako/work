extern crate rlang;

use std::error;
use rlang::codegen;
use rlang::parser;

fn main() {
    prog().unwrap();
}

fn prog() -> Result<(), Box<dyn error::Error>>{
    let src = "func main(a:int b:int):int { var a:int = 123; return a + b; }";
    let (_, prog) = parser::parse(src)?;
    //println!("{:?}", prog);

    let code = codegen::gencode(&prog)?;
    codegen::dump(&code);
    Ok(())
}
