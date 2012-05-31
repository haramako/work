class Parser
  prechigh
    nonassoc UMINUS
    left '(' '['
    left '*' '/' '%'
    left '+' '-'
    left '<' '>' '<=' '>=' '==' '!='
    right '=' '+=' '-='
  preclow
  expect 0 /* must has no conflict */
rule

/****************************************************/
/* program */
program: statement_list
       
block: '{' statement_list '}' { result = val[1] }
     | '{' '}'                { result = [] }
/*     | statement_i            { result = [val[0]] } */
/*     | ';'                    { result = [] } */

statement_list: statement_list statement_i { result = val[0] + [val[1]] }
              | statement_i { result = [val[0]] }

/****************************************************/
/* statement */

statement_i: statement { info(val[0]) }

statement: options ';'
         | 'function' IDENT '(' var_decl_list_if ')' ':' type_decl options_if block
              { result = [:function, val[1], val[3], val[6], val[7] && val[7][1], val[8]] }
         | 'include' '(' STRING ')' ';'          { result = [:include, val[2]] }
         | 'var' var_decl_list ';'               { result = [:var, val[1]] }
         | 'const' var_decl_list ';'             { result = [:const, val[1]] }
         | 'include_bin' '(' option_list ')' ';' { result = [:include_bin, val[2]] }

         | 'if' '(' exp ')' block else_block { result = [:if, val[2], val[4], val[5]] }
         | 'loop' '(' ')' block { result = [:loop, val[3]] }
         | 'while' '(' exp ')' block { result = [:while, val[2], val[4]] }
         | 'break' ';' { result = [:break] }
         | 'continue' ';' { result = [:continue] }
         | 'return' ';' { result = [:return] }
         | 'return' exp ';' { result = [:return, val[1]] }

         |  exp ';' { result = [:exp, val[0]] }
         
else_block: | 'else' block { result = val[1] }

exp: '(' exp ')' { result = val[1] }
   | exp '='  exp { result = [:load, val[0], val[2]] }
   | exp '+'  exp { result = [:add, val[0], val[2]] }
   | exp '-'  exp { result = [:sub, val[0], val[2]] }
   | exp '*'  exp { result = [:mul, val[0], val[2]] }
   | exp '/'  exp { result = [:div, val[0], val[2]] }
   | exp '%'  exp { result = [:mod, val[0], val[2]] }
   | exp '+=' exp { result = [:load, val[0], [:add, val[0], val[2]]] }
   | exp '-=' exp { result = [:load, val[1],[:sub, val[0], val[2]]] }
   | exp '==' exp { result = [:eq, val[0], val[2]] }
   | exp '!=' exp { result = [:ne, val[0], val[2]] }
   | exp '<'  exp { result = [:lt, val[0], val[2]] }
   | exp '>'  exp { result = [:gt, val[0], val[2]] }
   | exp '<=' exp { result = [:le, val[0], val[2]] }
   | exp '>=' exp { result = [:ge, val[0], val[2]] }
   | '!' exp = UMINUS { result = [:not, val[1]] }
   | '-' exp = UMINUS { result = [:uminus, val[1]] }
   | '*' exp = UMINUS { result = [:deref, val[1]] }
   | '&' exp = UMINUS { result = [:ref, val[1]] }
   | exp '(' exp_list ')' { result = [:call, val[0], val[2]] }
   | exp '[' exp ']' { result = [:index, val[0], val[2]] }
   | '[' exp_list ']' { result = [:array, val[1]] }
   | NUMBER
   | IDENT
   | STRING

exp_list: exp_list ',' exp { result = val[0] + [val[2]] }
        | exp { result = [val[0]] }
        | { result = [] }

/****************************************************/
/* option */
options_if: | options
options : 'options' '(' option_list ')' { result = [:options, val[2]] }

option_list: option_list_sub { result = Hash[ *val[0] ] }
option_list_sub: option_list_sub ',' option { result = val[0] + val[2] }
               | option { result = val[0] }
option: IDENT ':' exp { result = [val[0],val[2]] }
    
/****************************************************/
/* var declaration */
var_decl_list_if: {result = [] } | var_decl_list
var_decl_list: var_decl_list ',' var_decl { result = val[0]+[val[2]] }
             | var_decl { result = [val[0]] }

var_decl: IDENT ':' type_decl var_init var_option { result = [val[0], val[2], val[3], val[4]] }

var_init: | '=' exp { result = val[1] }
var_option: | 'options' '(' option_list ')' { result = val[2] }

/****************************************************/
/* type declaration */
type_decl: type_decl type_modifier { result = val[1]+[val[0]]; }
         | IDENT { result = val[0] }

type_modifier: '[' exp ']'            { result = [:array, val[1]] }
             | '*'                    { result = [:pointer] }
             | '(' type_decl_list ')' ':' { result = [:lambda, val[1] ] }

type_decl_list: type_decl ',' type_decl { result = val[0] + [val[2]] }
              | type_decl { result = [val[0]] }
              | { result = [] }
               
end
