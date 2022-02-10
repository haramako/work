class Pandora::CodeGen::Parser
rule

default: namespace_decl table_decls { result = AST.new(val[0], val[1]) }

namespace_decl: | 'namespace' namespace_name ';' { result = val[1] }

namespace_name: IDENT | NAMESPACE

# for object
field_decls: { result = [] }
           | field_decl field_decls { result = list(val) }

field_decl: IDENT IDENT ';' { result = Field.new(Type.new(val[0]), val[1]) }

# for table
table_decls: { result = [] }
           | table_decl table_decls { result = list(val) }

table_decl: 'table' NUMBER IDENT key_list '{' index_decls '}'
                 { result = Table.new(val[1], val[2], val[3], val[5]) }
          | 'object'  IDENT '{' field_decls '}' { result = ObjectDecl.new(val[1], val[3]) }

index_decls: { result = [] }
           | index_decl index_decls { result = list(val) }

index_decl: 'index' NUMBER key_list ';' { result = Index.new(val[1], val[2], []) }

key_list: '(' keys ')' { result = val[1] }

keys: { result = [] }
    | key { result = [val[0]] }
    | key ',' keys { result = list2(val) }

key: IDENT



end
