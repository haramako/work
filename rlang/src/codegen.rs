use crate::parser as p;

use std::collections::HashMap;
use std::fmt;
use std::rc::Rc;

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

#[derive(Debug, Copy, Clone)]
pub enum UnaryOp {
    Not,
}

#[derive(Debug, Copy, Clone)]
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
            Code::BinOp(op, t, r, r1, r2) => write!(f, "{:?} = {:?} {:?} {:?} {:?}", r, op, t, r1, r2)?,
            Code::Ret(t, r) => write!(f, "ret {:?} {:?}", t, r)?,
            Code::Call(func, args) => write!(f, "call {:?} {:?}", func, args)?,
            Code::Load(t, r, r1) => write!(f, "{:?} = load {:?} {:?}", r, t, r1)?,
            Code::LoadNum(t, r, n) => write!(f, "{:?} = load {:?} {:?}", r, t, n)?,
            Code::Store(t, r, r1) => write!(f, "store {:?} {:?} {:?}", t, r, r1)?,
            _ => {},
        }
        Ok(())
    }
}

#[derive(Debug)]
pub struct Err {}

#[derive(Debug)]
pub struct Func {
    pub id: p::Ident,
    pub code: Vec<Code>,
}

pub struct CodeGenerator {
    code: Vec<Code>,
    funcs: Vec<Rc<Func>>,
    regs: HashMap<String, Rc<Reg>>,
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

impl CodeGenerator {
    pub fn to_type(typ: &p::Type) -> Type {
        match typ {
            p::Type::Ident(t) => match t.name.as_str() {
                "int" => Type::I8,
                _ => panic!(),
            },
            _ => panic!(),
        }
    }

    fn op_type(&self, t1: Type, t2: Type) -> Type {
        t1
    }

    pub fn new_reg(&mut self, name: &str, typ: Type) -> Rc<Reg> {
        let reg = Rc::new(Reg {
            name: format!("%{}", name),
            idx: self.regs.len() as i32 + 1,
            typ: typ,
        });
        self.regs.insert(name.to_owned(), reg.clone());
        reg
    }

    pub fn tmpreg(&mut self, typ: Type) -> Rc<Reg> {
        self.new_reg(format!("{}", self.regs.len() + 1).as_str(), typ)
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
                self.code.push(Code::Ret(Type::I8, r));
                Ok(())
            }
            _ => Ok(()),
        }
    }

    pub fn genfunc(&mut self, id: &p::Ident, typ: &p::Type, args: &Vec<p::Ident>, body: &Vec<p::Stmt>) -> Result<(), Err> {
        let mut func = Func{id:id.clone(), code: Vec::new()};
        self.genprog(body)?;
        func.code = self.code.clone();
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

pub fn gencode(prog: &Vec<p::Stmt>) -> Result<Vec<Code>, Err> {
    let mut cg = CodeGenerator {
        code: Vec::new(),
        funcs: Vec::new(),
        regs: HashMap::new(),
    };
    cg.genprog(prog)?;
    Ok(cg.code)
}

pub fn dump(code: &Vec<Code>) {
    for c in code.iter() {
        println!("{:?}", c);
    }
}