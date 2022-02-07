class Pandora::CodeGen::Parser
rule

table_decl: TABLE NUMBER IDENT IDENT '{' index_decls '}' { result = Table.new(val[1], val[2], val[3], val[5]) }

index_decls: { result = [] }
| index_decl index_decls { result = [val[0]].concat(val[1]) }

index_decl: INDEX NUMBER params ';' { result = Index.new(val[1], val[2], []) }
| KEY NUMBER params ';' { result = Index.new(val[1], val[2], ['unique']) }

params: '(' param_list ')' { result = val[1] }

param_list: { result = [] }
| param_element { result = [val[0]] }
| param_element ',' param_list { result = [val[0]].concat(val[2]) }

param_element: IDENT IDENT { result = Param.new(val[0], val[1]) }

end
