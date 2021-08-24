use nom_locate::LocatedSpan;
use nom_recursive::{recursive_parser, RecursiveInfo};
use std::fmt;

use nom::{
    branch::*,
    bytes::complete::*,
    character::complete::*,
    combinator::{map, map_res},
    multi::*,
    sequence::*,
    IResult,
};

type Span<'a> = LocatedSpan<&'a str, RecursiveInfo>;

#[derive(Clone)]
pub struct Ident {
    pub name: String,
}

impl fmt::Debug for Ident {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.name)?;
        Ok(())
    }
}

fn skip_spaces(input: Span) -> Span {
    Span::from(input.trim_start())
}

// tokens
fn number(input: Span) -> IResult<Span, i32> {
    let (input, n) = map_res(digit1, |s: Span| s.parse::<i32>())(input)?;
    Ok((skip_spaces(input), n))
}

fn kw<'a>(keyword: &'a str) -> impl Fn(Span) -> IResult<Span, Span> + 'a {
    move |input: Span| {
        let (input, id) = tag(keyword)(input)?;
        Ok((skip_spaces(input), id))
    }
}

/*
fn kw2<'a>(s: &'a str, keyword: &'a str)-> IResult<&'a str,&'a str>{
    let (s, id) = tag(keyword)(s)?;
    Ok((skip_spaces(s),id))
}
*/

fn ident(input: Span) -> IResult<Span, Ident> {
    let (input, id) = alphanumeric1(input)?;
    Ok((
        skip_spaces(input),
        Ident {
            name: id.to_string(),
        },
    ))
}

/*
macro_rules! kw {
    ($s:ident, $x:expr) => {let ($s, _) = kw2($s, $x)?;}
}
*/

// statements
#[derive(Debug)]
pub enum Stmt {
    Func(Ident, Type, Vec<Ident>, Vec<Stmt>),
    VarDecl(Ident, Type, Option<Expr>),
    Return(Expr),
    Expr(Expr),
}

#[derive(Debug)]
pub enum Expr {
    BinOp(String, Box<Expr>, Box<Expr>),
    Number(i32),
    Ident(Ident),
}

#[derive(Debug)]
pub enum Type {
    Ident(Ident),
    Pointer(Box<Type>),
    //Array(Box<Type>, i32),
    Func(Box<Type>, Vec<Type>),
}

fn func(s: Span) -> IResult<Span, Stmt> {
    let (s, (_, id, _, args, _, _, t, blk)) = tuple((
        kw("func"),
        ident,
        kw("("),
        arg_list,
        kw(")"),
        kw(":"),
        typ,
        block,
    ))(s)?;
    let (ids, typs): (Vec<_>, Vec<_>) = args.into_iter().unzip();
    let t = Type::Func(Box::new(t), typs);
    Ok((s, Stmt::Func(id, t, ids, blk)))
}

fn arg_decl(s: Span) -> IResult<Span, (Ident, Type)> {
    let (s, (id, _, t)) = tuple((ident, kw(":"), typ))(s)?;
    Ok((s, (id, t)))
}

fn arg_list(s: Span) -> IResult<Span, Vec<(Ident, Type)>> {
    many0(arg_decl)(s)
}

fn var_decl(s: Span) -> IResult<Span, Stmt> {
    let (s, (_, id, _, t, _, expr, _)) =
        tuple((kw("var"), ident, kw(":"), typ, kw("="), expr, kw(";")))(s)?;
    Ok((s, Stmt::VarDecl(id, t, Some(expr))))
}

fn return_stmt(s: Span) -> IResult<Span, Stmt> {
    let (s, (_, e, _)) = tuple((kw("return"), expr, kw(";")))(s)?;
    Ok((s, Stmt::Return(e)))
}

fn expr_stmt(s: Span) -> IResult<Span, Stmt> {
    let (s, (e, _)) = tuple((expr, kw(";")))(s)?;
    Ok((s, Stmt::Expr(e)))
}

fn stmt(s: Span) -> IResult<Span, Stmt> {
    alt((func, var_decl, return_stmt, expr_stmt))(s)
}

fn stmt_list(s: Span) -> IResult<Span, Vec<Stmt>> {
    many0(stmt)(s)
}

fn block(s: Span) -> IResult<Span, Vec<Stmt>> {
    let (s, (_, r, _)) = tuple((kw("{"), stmt_list, kw("}")))(s)?;
    Ok((s, r))
}

#[recursive_parser]
fn binop(s: Span) -> IResult<Span, Expr> {
    let (s, (lhs, op, rhs)) = tuple((expr, kw("+"), expr))(s)?;
    Ok((s, Expr::BinOp(op.to_string(), Box::new(lhs), Box::new(rhs))))
}

fn term(s: Span) -> IResult<Span, Expr> {
    alt((
        map(number, |t| Expr::Number(t)),
        map(ident, |t| Expr::Ident(t)),
    ))(s)
}

fn typ(s: Span) -> IResult<Span, Type> {
    alt((
        map(ident, |t| Type::Ident(t)),
        map(tuple((kw("*"), typ)), |(_, t)| Type::Pointer(Box::new(t))),
    ))(s)
}

fn expr(s: Span) -> IResult<Span, Expr> {
    alt((binop, term))(s)
}

pub fn parse<'a>(src:&str) -> Option<Vec<Stmt>>{
    stmt_list(Span::from(src)).map(|(_,r)| r).ok()
}
