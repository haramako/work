#include <stdint.h>
#include <stddef.h>
#include <assert.h>
#include <stdbool.h>

/**
 * Value.
 * 0.0000: nil
 * 0.0010: t
 * xxxxx1: Number
 * xxx010: Atom      ( >= VALUE_MIN_POINTER )
 * xxx100: CFunction ( >= VALUE_MIN_POINTER )
 * xxx000: Cell      ( >= VALUE_MIN_POINTER )
 */
typedef uintptr_t Value;

typedef enum {
	TYPE_NIL = 0,
	TYPE_T   = 1,
	TYPE_INT = 2,
	TYPE_ATOM = 3,
	TYPE_CELL = 4,
	TYPE_CFUNCTION = 5,
} Type;

#define TYPE_MASK_INT 1
#define VALUE_MIN_POINTER 32

#define VALUE_T 2

typedef struct Atom {
	char *str;
	struct Atom *next;
} Atom;

typedef Value (*CFunctionFunc)( Value args );

typedef enum {
	C_FUNCTION_TYPE_FUNC = 0,
	C_FUNCTION_TYPE_SPECIAL,
	C_FUNCTION_TYPE_MACRO,
} CFunctionType;

typedef struct {
	CFunctionFunc func;
	CFunctionType type;
} CFunction; 

typedef struct {
	Value car;
	Value cdr;
} Cell;

typedef struct NameEntry {
	Value name;
	Value val;
	struct NameEntry *next;
} NameEntry;

#define NIL 0L

inline int V_IS_INT( Value v ){ return (v & 1) > 0; }
inline int V_IS_ATOM( Value v ){ return v >= VALUE_MIN_POINTER && (v & 7) == 2; }
inline int V_IS_CELL( Value v ){ return v >= VALUE_MIN_POINTER && (v & 7) == 0; }
inline int V_IS_CFUNCTION( Value v ){ return v >= VALUE_MIN_POINTER && (v & 7) == 4; }

inline int V2INT( Value v ){ assert( V_IS_INT(v) ); return (intptr_t)v >> 1; }
inline Value INT2V( int i ){ return ((Value)i) << 1 | 1; }
inline Atom* V2ATOM( Value v ){ assert( V_IS_ATOM(v) ); return (Atom*)(v & ~7); }
inline Value ATOM2V( Atom* atom ){ return ((Value)atom) | 2; }
inline CFunction* V2CFUNCTION( Value v ){ assert( V_IS_CFUNCTION(v) ); return (CFunction*)(v & ~7); }
inline Value CFUNCTION2V( CFunction *f ){ return ((Value)f) | 4; }
inline Cell* V2CELL( Value v ){ assert( V_IS_CELL(v) ); return (Cell*)v; }
inline Value CELL2V( Cell* c ){ return (Value)c; }

inline Value CAR( Value v ){ return V2CELL(v)->car; }
inline Value CDR( Value v ){ return V2CELL(v)->cdr; }

inline Type TYPE_OF( Value v )
{
	if( v == 0 ){
		return TYPE_NIL;
	}else if( v == VALUE_T ){
		return TYPE_T;
	}else if( v & TYPE_MASK_INT ){
		return TYPE_INT;
	}else if( (v & 7) == 2 ){
		return TYPE_ATOM;
	}else if( (v & 7) == 4 ){
		return TYPE_CFUNCTION;
	}else{
		return TYPE_CELL;
	}
}

Value cons( Value car, Value cdr );

size_t value_to_str( char *buf, Value v );

Atom* atom_new( const char *str );
Atom* atom_find( const char *str );
inline Value intern( const char *str ){ return ATOM2V(atom_find(str)); }

Value parse( char *src );
Value parse_list( char *src );

void register_cfunc( char *sym, CFunctionType type, CFunctionFunc func );
inline void defun( char *sym, CFunctionFunc func ){ return register_cfunc( sym, C_FUNCTION_TYPE_FUNC, func ); }
inline void defspecial( char *sym, CFunctionFunc func ){ return register_cfunc( sym, C_FUNCTION_TYPE_SPECIAL, func ); }
Value name_find( Value name );
void name_add( Value name, Value v );

Value eval( Value v );
Value eval_list( Value v );
void init();
void cfunc_init();

void print_val( Value v );
