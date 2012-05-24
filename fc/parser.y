class FcParser
  prechigh
    nonassoc UMINUS
    left '(' '['
    left '*' '/'
    left '+' '-'
    right '='
  preclow
  
rule

program: function

function: 'function' IDENT '(' arg_list ')' block { result = [:function, val[3], val[5]] }

arg_list: arg_list ',' IDENT { result = val[0] + [val[2]] }
        | IDENT { result = [val[0]] }

block: '{' statement_list '}' { result = val[1] }
     | statement              { result = [val[0]] }

statement_list: statement_list statement { result = val[0] + [val[1]] }
              | statement { result = [val[0]] }

statement: exp ';' { result = val[0] }
         | 'if' '(' exp ')' block else_block { result = [:if, val[2], val[4], val[5]] }
         | 'while' '(' exp ')' block { result = [:while, val[2], val[1]] }
         | 'var' arg_list ';' { result = [:var, val[1]] }
         
else_block: | 'else' block { result = val[1] }

exp: exp '=' exp { result = [:put, val[0], val[2]] }
   | exp '+' exp { result = [:add, val[0], val[2]] }
   | exp '-' exp { result = [:sub, val[0], val[2]] }
   | exp '*' exp { result = [:mul, val[0], val[2]] }
   | exp '/' exp { result = [:div, val[0], val[2]] }
   | exp '(' exp_list ')' { result = [:call, val[0], val[2]] }
   | exp '[' exp ']' { result = [:call, val[0], val[2]] }
   | '-' exp = UMINUS { result = [:uminus, val[1]] }
   | NUMBER { result = val[0] }
   | IDENT  { result = val[0] }
   | STRING { result = val[0] }

exp_list: exp_list ',' exp { result = val[0] + [val[2]] }
        | exp { result = [val[0]] }
        | { result = [] }
   
end
