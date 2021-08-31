use crate::parser as p;

use std::cmp::max;
use std::collections::HashMap;
use std::fmt;
use std::rc::Rc;
use thiserror::Error;

pub type Symbol = String;

#[derive(Clone)]
pub struct Reg {
    idx: i32,
    name: String,
    typ: Type,
}

impl fmt::Debug for Reg {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.name)?;
        Ok(())
    }
}

#[derive(Debug, Copy, Clone)]
pub enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
    And,
    Or,
    Xor,
}

impl BinOp {
    pub fn to_asm(self) -> String {
        format!("{:?}", self).to_lowercase()
    }
}

#[derive(Debug, Copy, Clone)]
pub enum UnaryOp {
    Not,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum Type {
    I8,
    I16,
    I32,
    I64,
    U8,
    U16,
    U32,
    U64,
    UPtr,
}

impl Type {
    pub fn to_asm(self) -> &'static str {
        match self {
            Type::I8 => "i8",
            Type::I16 => "i16",
            Type::I32 => "i32",
            Type::I64 => "i64",
            Type::U8 => "i8",
            Type::U16 => "i16",
            Type::U32 => "i32",
            Type::U64 => "i64",
            Type::UPtr => "i64",
        }
    }

    pub fn size(self) -> i32 {
        match self {
            Type::I8 => 1,
            Type::I16 => 2,
            Type::I32 => 4,
            Type::I64 => 8,
            Type::U8 => 1,
            Type::U16 => 2,
            Type::U32 => 4,
            Type::U64 => 8,
            Type::UPtr => 8,
        }
    }

    pub fn signed(self) -> bool {
        match self {
            Type::I8 => true,
            Type::I16 => true,
            Type::I32 => true,
            Type::I64 => true,
            Type::U8 => false,
            Type::U16 => false,
            Type::U32 => false,
            Type::U64 => false,
            Type::UPtr => false,
        }
    }

    pub fn from(size: i32, signed: bool) -> Type {
        if signed {
            match size {
                1 => Type::I8,
                2 => Type::I16,
                4 => Type::I32,
                8 => Type::I64,
                _ => panic!(),
            }
        } else {
            match size {
                1 => Type::U8,
                2 => Type::U16,
                4 => Type::U32,
                8 => Type::U64,
                _ => panic!(),
            }
        }
    }

    pub fn combinate(t1: Type, t2: Type) -> Type {
        if t1 == t2 {
            t1
        } else if t1.signed() == t2.signed() {
            Type::from(max(t1.size(), t2.size()), t1.signed())
        } else {
            panic!();
        }
    }
}

#[derive(Clone)]
pub enum Code {
    Label(Symbol),
    BinOp(BinOp, Type, Rc<Reg>, Rc<Reg>, Rc<Reg>),
    UnaryOp(UnaryOp, Type, Rc<Reg>, Rc<Reg>),
    Ret(Type, Rc<Reg>),
    Call(Rc<Func>, Vec<(Type, Rc<Reg>)>),
    Load(Type, Rc<Reg>, Rc<Reg>),
    LoadNum(Type, Rc<Reg>, i32),
    Store(Type, Rc<Reg>, Rc<Reg>),
}

impl fmt::Debug for Code {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Code::Label(sym) => write!(f, "{}", sym)?,
            Code::BinOp(op, t, r, r1, r2) => write!(
                f,
                "{:?} = {} {} {:?}, {:?}",
                r,
                op.to_asm(),
                t.to_asm(),
                r1,
                r2
            )?,
            Code::Ret(t, r) => write!(f, "ret {} {:?}", t.to_asm(), r)?,
            Code::Call(func, args) => write!(f, "call {:?} {:?}", func, args)?,
            Code::Load(t, r, r1) => write!(f, "{:?} = load {:?} {:?}", r, t, r1)?,
            Code::LoadNum(t, r, n) => write!(f, "{:?} = load {:?} {:?}", r, t, n)?,
            Code::Store(t, r, r1) => write!(f, "store {:?} {:?} {:?}", t, r, r1)?,
            _ => {}
        }
        Ok(())
    }
}

#[derive(Error, Debug)]
pub enum Err {
    #[error("unkonwn error")]
    Unknown,
}

#[derive(Debug)]
pub struct Func {
    pub id: p::Ident,
    pub code: Vec<Code>,
    pub typ: p::Type,
    pub ret_type: Type,
    pub args: Vec<Rc<Reg>>,
    pub regs: HashMap<String, Rc<Reg>>,
}

pub struct CodeGenerator {
    code: Vec<Code>,
    func_result: Type,

    funcs: Vec<Rc<Func>>,
    regs: HashMap<String, Rc<Reg>>,
    reg_num: i32,
}

fn op_to_op(op: &str) -> BinOp {
    match op {
        "+" => BinOp::Add,
        "-" => BinOp::Sub,
        "*" => BinOp::Mul,
        "/" => BinOp::Div,
        _ => panic!(),
    }
}

pub fn to_type(typ: &p::Type) -> Type {
    match typ {
        p::Type::Ident(t) => match t.name.as_str() {
            "int" => Type::I8,
            _ => panic!(),
        },
        _ => panic!(),
    }
}

impl CodeGenerator {
    fn op_type(&self, t1: Type, t2: Type) -> Type {
        Type::combinate(t1, t2)
    }

    pub fn new_reg(&mut self, name: &str, typ: Type) -> Rc<Reg> {
        let reg = Rc::new(Reg {
            name: format!("%{}", name),
            idx: (self.regs.len() + 1) as i32,
            typ: typ,
        });
        self.regs.insert(name.to_owned(), reg.clone());
        reg
    }

    pub fn tmpreg(&mut self, typ: Type) -> Rc<Reg> {
        self.reg_num+=1;
        self.new_reg(format!("{}", self.reg_num).as_str(), typ)
    }

    pub fn genexpr(&mut self, expr: &p::Expr) -> Result<Rc<Reg>, Err> {
        match expr {
            p::Expr::BinOp(op, e1, e2) => {
                let r1 = self.genexpr(e1)?;
                let r2 = self.genexpr(e2)?;
                let reg = self.tmpreg(self.op_type(r1.typ, r2.typ));
                self.code
                    .push(Code::BinOp(op_to_op(op), Type::I8, reg.clone(), r1, r2));
                Ok(reg)
            }
            p::Expr::Ident(id) => Ok(self.new_reg(id.name.as_str(), Type::I8)),
            p::Expr::Number(n) => {
                let reg = self.tmpreg(Type::I8);
                self.code.push(Code::LoadNum(Type::I8, reg.clone(), *n));
                Ok(reg)
            }
        }
    }

    pub fn genstmt(&mut self, stmt: &p::Stmt) -> Result<(), Err> {
        match stmt {
            p::Stmt::Func(id, typ, args, body) => self.genfunc(id, typ, args, body),
            p::Stmt::Return(expr) => {
                let r = self.genexpr(expr)?;
                self.code.push(Code::Ret(self.func_result, r));
                Ok(())
            }
            _ => Ok(()),
        }
    }

    pub fn genfunc(
        &mut self,
        id: &p::Ident,
        typ: &p::Type,
        args: &Vec<p::Ident>,
        body: &Vec<p::Stmt>,
    ) -> Result<(), Err> {
        let ret_type: Type;
        let args2: Vec<Rc<Reg>>;

        match typ {
            p::Type::Func(res, arg_types) => {
                ret_type = to_type(res);
                args2 = args
                    .iter()
                    .zip(arg_types)
                    .map(|(arg, typ)| self.new_reg(arg.name.as_str(), to_type(typ)))
                    .collect::<Vec<_>>();
            }
            _ => panic!(),
        }

        let mut func = Func {
            id: id.clone(),
            typ: typ.clone(),
            code: Vec::new(),
            regs: HashMap::new(),
            ret_type: ret_type,
            args: args2,
        };

        self.genprog(body)?;

        std::mem::swap(&mut func.code, &mut self.code);
        std::mem::swap(&mut func.regs, &mut self.regs);
        self.reg_num = 0;
        self.funcs.push(Rc::new(func));

        Ok(())
    }

    pub fn genprog(&mut self, prog: &Vec<p::Stmt>) -> Result<(), Err> {
        for s in prog.iter() {
            self.genstmt(s)?
        }
        Ok(())
    }
}

pub fn gencode(prog: &Vec<p::Stmt>) -> Result<CodeGenerator, Err> {
    let mut cg = CodeGenerator {
        code: Vec::new(),
        func_result: Type::I8,

        funcs: Vec::new(),
        regs: HashMap::new(),
        reg_num: 0,
    };
    cg.genprog(prog)?;
    Ok(cg)
}

pub fn dump(cg: &CodeGenerator) {
    println!(r#"source_filename = "hoge.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu""#);
    
    for f in cg.funcs.iter() {
        let args = f
            .args
            .iter()
            .map(|reg| format!("{} {}", reg.typ.to_asm(), reg.name))
            .collect::<Vec<_>>()
            .join(", ");

        println!(
            "define {} @{:?}({}) {}",
            f.ret_type.to_asm(),
            f.id,
            args,
            "{"
        );

        for c in f.code.iter() {
            println!("  {:?}", c);
        }
        println!("{}", "}");
    }
}
