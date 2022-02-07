class Pandora::CodeGen::Parser
rule

prog: namespace_decl table_decls { result = Prog.new(val[0], val[1]) }

namespace_decl: | 'namespace' namespace_name ';' { result = val[1] }

namespace_name: IDENT | NAMESPACE

table_decls: { result = [] }
| table_decl table_decls { result = [val[0]].concat(val[1]) }

table_decl: 'table' NUMBER IDENT IDENT params '{' index_decls '}' { result = Table.new(val[1], val[2], val[3], val[4], val[6]) }

index_decls: { result = [] }
| index_decl index_decls { result = [val[0]].concat(val[1]) }

index_decl: 'index' NUMBER params ';' { result = Index.new(val[1], val[2], []) }
| KEY NUMBER params ';' { result = Index.new(val[1], val[2], ['unique']) }

params: '(' param_list ')' { result = val[1] }

param_list: { result = [] }
| param_element { result = [val[0]] }
| param_element ',' param_list { result = [val[0]].concat(val[2]) }

param_element: IDENT IDENT { result = Param.new(Type.new(val[0]), val[1]) }

end
