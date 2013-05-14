#include <stdint.h>
#include <stddef.h>
#include <assert.h>
#include <stdbool.h>

/**
 * Value.
 * 0.0000: nil
 * 0.0100: #t
 * 0.0110: #f
 * xxxxx1: Number
 * xxx010: Symbol    ( >= VALUE_MIN_POINTER )
 * xxx100: CFunction ( >= VALUE_MIN_POINTER )
 * xxx000: Cell      ( >= VALUE_MIN_POINTER )
 */
typedef uintptr_t Value;

typedef enum {
	TYPE_NIL  = 0,
	TYPE_BOOL = 1,
	TYPE_INT  = 2,
	TYPE_SYMBOL = 3,
	TYPE_CELL = 4,
	TYPE_CFUNCTION = 5,
} Type;

#define TYPE_MASK_INT 1
#define VALUE_MIN_POINTER 32

typedef struct Symbol {
	char *str;
	struct Symbol *next;
} Symbol;

typedef Value (*CFunctionFunc)( Value args );

typedef enum {
	C_FUNCTION_TYPE_LAMBDA = 0,
	C_FUNCTION_TYPE_FUNC,
	C_FUNCTION_TYPE_SPECIAL,
	C_FUNCTION_TYPE_MACRO,
} CFunctionType;

typedef struct Slot {
	Value name;
	Value val;
	struct Slot *next;
} Slot;

typedef struct Bundle {
	Slot *head;
	struct Bundle *upper;
} Bundle;

typedef struct {
	CFunctionType type;
	int arity;
	Value args;
	Value body;
	Bundle *bundle;
	CFunctionFunc func;
} CFunction; 

typedef struct {
	Value car;
	Value cdr;
} Cell;

#define NIL 0L
#define VALUE_T 4L
#define VALUE_F 6L

inline bool V_IS_INT( Value v ){ return (v & 1) > 0; }
inline bool V_IS_SYMBOL( Value v ){ return v >= VALUE_MIN_POINTER && (v & 7) == 2; }
inline bool V_IS_CELL( Value v ){ return v >= VALUE_MIN_POINTER && (v & 7) == 0; }
inline bool V_IS_CFUNCTION( Value v ){ return v >= VALUE_MIN_POINTER && (v & 7) == 4; }
inline bool V_IS_POINTER( Value v ){ return V_IS_CELL(v) || V_IS_CFUNCTION(v); }

inline int V2INT( Value v ){ assert( V_IS_INT(v) ); return (intptr_t)v >> 1; }
inline Value INT2V( int i ){ return ((Value)i) << 1 | 1; }
inline Symbol* V2SYMBOL( Value v ){ assert( V_IS_SYMBOL(v) ); return (Symbol*)(v & ~7); }
inline Value SYMBOL2V( Symbol* atom ){ return ((Value)atom) | 2; }
inline CFunction* V2CFUNCTION( Value v ){ assert( V_IS_CFUNCTION(v) ); return (CFunction*)(v & ~7); }
inline Value CFUNCTION2V( CFunction *f ){ return ((Value)f) | 4; }
inline Cell* V2CELL( Value v ){ assert( V_IS_CELL(v) ); return (Cell*)v; }
inline Value CELL2V( Cell* c ){ return (Value)c; }
inline void* V2POINTER( Value v ){ return (void*)(v&~7); }

#define CAR(v) (V2CELL(v)->car)
#define CDR(v) (V2CELL(v)->cdr)
#define CAAR(v) (CAR(CAR(v)))
#define CADR(v) (CDR(CAR(v)))
#define CDAR(v) (CAR(CDR(v)))
#define CDDR(v) (CDR(CDR(v)))
inline Value first( Value v ){ return CAR(v); }
inline Value second( Value v ){ return CAR(CDR(v)); }
inline Value third( Value v ){ return CAR(CDR(CDR(v))); }

Type TYPE_OF( Value v );
Value cons( Value car, Value cdr );
size_t value_to_str( char *buf, Value v );
Value intern( const char *sym );
size_t value_length( Value v );
CFunction* lambda_new();

// Bundle and Slot

extern Bundle* bundle_cur;
Bundle* bundle_new( Bundle *upper );
bool bundle_set( Bundle *b, Value sym, Value v );
void bundle_define( Bundle *b, Value sym, Value v );
bool bundle_find( Bundle *b, Value sym, Value *result );

// Parsing

Value parse( char *src );
Value parse_list( char *src );

void register_cfunc( char *sym, CFunctionType type, CFunctionFunc func );
inline void defun( char *sym, CFunctionFunc func ){ return register_cfunc( sym, C_FUNCTION_TYPE_FUNC, func ); }
inline void defspecial( char *sym, CFunctionFunc func ){ return register_cfunc( sym, C_FUNCTION_TYPE_SPECIAL, func ); }

Value eval( Value v );
Value eval_list( Value v );
Value begin( Value v );
void display_val( char *str, Value args );
Value display( Value v );

extern Value retained;

inline Value retain( Value v ){ retained = cons( v, retained ); return v; }
Value release( Value v );
void gc();

void init();
void cfunc_init();
