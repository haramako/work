#include "lisp.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <setjmp.h>
#include "gc.h"

inline void value_mark( Value v ){
	if( V_IS_CELL(v) ){
		gc_mark(V2CELL(v));
	}else if( V_IS_CFUNCTION(v) ){
		gc_mark(V2CFUNCTION(v));
	}
}

static void _Cell_mark( void *p )
{
	// display_val( "mark: ", (Value)p );
	Cell *cell = V2CELL((Value)p);
	value_mark( cell->car );
	value_mark( cell->cdr );
}

static void _value_free( void *p )
{
	// display_val( "free: ", (Value)p );
}

static void _free( void *p )
{
	// printf( "free: %p\n", p );
}

static void _Slot_mark( void *p )
{
	// printf( "mark slot: %p\n", p );
	Slot *s = (Slot*)p;
	value_mark( s->name );
	value_mark( s->val );
	gc_mark( s->next );
}

static void _Bundle_mark( void *p )
{
	// printf( "mark bundle: %p\n", p );
	Bundle *b = (Bundle*)p;
	gc_mark( b->upper );
	gc_mark( b->head );
}

static void _CFunction_mark( void *p )
{
	CFunction *f = (CFunction*)p;
	// display_val( "mark_func: ", CFUNCTION2V(f) );
	value_mark( f->args );
	value_mark( f->body );
	if( f->bundle ) gc_mark( f->bundle );
}

gc_vtbl Cell_vtbl = { _Cell_mark, _value_free };
gc_vtbl Slot_vtbl = { _Slot_mark, _free };
gc_vtbl Bundle_vtbl = { _Bundle_mark, _free };
gc_vtbl CFunction_vtbl = { _CFunction_mark, _value_free };

Type TYPE_OF( Value v )
{
	if( v == 0 ){
		return TYPE_NIL;
	}else if( v == VALUE_T || v == VALUE_F ){
		return TYPE_BOOL;
	}else if( v & TYPE_MASK_INT ){
		return TYPE_INT;
	}else if( (v & 7) == 2 ){
		return TYPE_SYMBOL;
	}else if( (v & 7) == 4 ){
		return TYPE_CFUNCTION;
	}else{
		return TYPE_CELL;
	}
}

Value cons( Value car, Value cdr )
{
	Cell *new_cell = GC_MALLOC(Cell);
	if( !new_cell ) assert(0);
	new_cell->car = car;
	new_cell->cdr = cdr;
	return (Value)new_cell;
}

size_t value_length( Value v )
{
	assert( V_IS_CELL(v) );
	size_t len = 0;
	for( Value cur=v; cur != NIL; cur = CDR(cur) ) len++;
	return len;
}

size_t value_to_str( char *buf, Value v )
{
	char *orig_buf = buf;
	// printf( "%d\n", TYPE_OF(v) );
	switch( TYPE_OF(v) ){
	case TYPE_NIL:
		buf += sprintf( buf, "()" );
		break;
	case TYPE_BOOL:
		buf += sprintf( buf, (v==VALUE_T)?"#t":"#f" );
		break;
	case TYPE_INT:
		buf += sprintf( buf, "%d", V2INT(v) );
		break;
	case TYPE_SYMBOL:
		buf += sprintf( buf, "%s", V2SYMBOL(v)->str );
		break;
	case TYPE_CFUNCTION:
		{
			CFunction *lmd = V2CFUNCTION(v);
			switch( lmd->type ){
			case C_FUNCTION_TYPE_LAMBDA:
				buf += sprintf( buf, "(LAMBDA:%p)", V2CFUNCTION(v) );
				break;
			case C_FUNCTION_TYPE_MACRO:
				buf += sprintf( buf, "(MACRO:%p)", V2CFUNCTION(v) );
				break;
			case C_FUNCTION_TYPE_FUNC:
				buf += sprintf( buf, "(CFUNCTION:%p)", V2CFUNCTION(v) );
				break;
			case C_FUNCTION_TYPE_SPECIAL:
				buf += sprintf( buf, "(SPECIAL:%p)", V2CFUNCTION(v) );
				break;
			default:
				assert(0);
			}
		}
		break;
	case TYPE_CELL:
		buf += sprintf( buf, "(" );
		bool finished = false;
		while( !finished ){
			switch( TYPE_OF(CDR(v)) ){
			case TYPE_NIL:
				buf += value_to_str( buf, CAR(v) );
				finished = true;
				break;
			case TYPE_BOOL:
			case TYPE_INT:
			case TYPE_SYMBOL:
				buf += value_to_str( buf, CAR(v) );
				buf += sprintf( buf, " . " );
				buf += value_to_str( buf, CDR(v) );
				finished = true;
				break;
			case TYPE_CELL:
				buf += value_to_str( buf, CAR(v) );
				buf += sprintf( buf, " " );
				break;
			default:
				assert(0);
			}
			v = CDR(v);
		}
		buf += sprintf( buf, ")" );
		break;
	default:
		assert(0);
	}
	return buf - orig_buf;
}

CFunction* lambda_new()
{
	CFunction *lmd = GC_MALLOC(CFunction)
	assert( lmd );
	lmd->arity = 0;
	lmd->args = NIL;
	lmd->body = NIL;
	lmd->bundle = NULL;
	lmd->func = NULL;
	return lmd;
}

//********************************************************
// Symbol
//********************************************************

static Symbol *_symbol_root = NULL;
static int _gemsym_cur = 0;

Value intern( const char *sym )
{
	for( Symbol *cur = _symbol_root; cur != NULL; cur = cur->next ){
		if( strcmp( cur->str, sym ) == 0 ) return SYMBOL2V(cur);
	}
	// not found, create new atom
	Symbol *new_sym = malloc( sizeof(Symbol) );
	assert( new_sym );
	new_sym->str = malloc( strlen(sym)+1 );
	assert( new_sym->str );
	strcpy( new_sym->str, sym );
	new_sym->next = _symbol_root;
	_symbol_root = new_sym;
	return SYMBOL2V(new_sym);
}

static Value _gemsym( Value args )
{
	Symbol *new_sym = malloc( sizeof(Symbol) );
	assert( new_sym );
	new_sym->str = malloc( 8 );
	assert( new_sym->str );
	sprintf( new_sym->str, "$%d", _gemsym_cur );
	_gemsym_cur++;
	new_sym->next = _symbol_root;
	_symbol_root = new_sym;
	return SYMBOL2V(new_sym);
}


//********************************************************
// Bundle and Slot
//********************************************************

Bundle* bundle_cur = NULL;

Bundle* bundle_new( Bundle *upper )
{
	Bundle *new_bundle = GC_MALLOC( Bundle );
	assert( new_bundle );
	new_bundle->head = NULL;
	new_bundle->upper = upper;
	return new_bundle;
}

Slot* bundle_find_slot( Bundle *b, Value sym, bool find_upper )
{
	for( Slot *cur = b->head; cur != NULL; cur = cur->next ){
		if( cur->name == sym ) return cur;
	}
	if( find_upper && b->upper ) return bundle_find_slot( b->upper, sym, find_upper );
	return NULL;
}

bool bundle_set( Bundle *b, Value sym, Value v )
{
	Slot *slot = bundle_find_slot( b, sym, true );
	assert( slot );
	slot->val = v;
	return true;
}

void bundle_define( Bundle *b, Value sym, Value v )
{
	assert( !bundle_find_slot( b, sym, false ) );
	// not found, create new entry
	Slot *slot = GC_MALLOC(Slot);
	assert( slot );
	slot->name = sym;
	slot->val = v;
	slot->next = b->head;
	b->head = slot;
}

bool bundle_find( Bundle *b, Value sym, Value *result )
{
	Slot *slot = bundle_find_slot( b, sym, true );
	if( slot ){
		*result = slot->val;
		return true;
	}else{
		return false;
	}
}

//********************************************************
// Parsing
//********************************************************

typedef struct {
	char *src;
	char *cur;
	int line;
} ParseState;

int _parse( ParseState *state, Value *result );

void _skip_space( ParseState *state )
{
	char c;
	while( (c = *state->cur) ){
		switch( c ){
		case ' ': case '\t': case '\n':
			break;
		default:
			return;
		}
		state->cur++;
	}
}


int _parse_list( ParseState *state, Value *result )
{
	Value val;
	_skip_space( state );
	switch( *state->cur ){
	case ')':
	case '\0':
		*result = NIL;
		return 0;
	default:
		{
			Value cdr;
			_parse( state, &val );
			_parse_list( state, &cdr );
			*result = cons( val, cdr );
			return 0;
		}
	}
}

static inline bool _is_val_char( char c )
{
	switch( c ){
	case ' ': case '\t': case '\n': case '(': case ')': case '\0':
		return false;
	default:
		return true;
	}
}

static Value _parse_token( const char *start, const char *end )
{
	if( isnumber(start[0]) || ( start[0] == '-' && isnumber(start[1]) ) ){
		return INT2V(atoi(start));
	}else{
		char tmp[32];
		memcpy( tmp, start, end-start );
		tmp[end-start] = '\0';
		return intern( tmp );
	}
}

int _parse( ParseState *state, Value *result )
{
	int err;
	_skip_space( state );
	switch( *state->cur ){
	case '\0':
		return 1;
	case '(':
		state->cur++;
		err = _parse_list( state, result );
		assert( *state->cur == ')' );
		state->cur++;
		return err;
	case ')':
		assert(0);
	case '#':
		state->cur++;
		if( *state->cur == 't' ){
			state->cur++;
			*result = VALUE_T;
			return 0;
		}else if( *state->cur == 'f' ){
			state->cur++;
			*result = VALUE_F;
			return 0;
		}else{
			assert(0);
		}
	case '\'':
		state->cur++;
		err = _parse( state, result );
		if( err ) return err;
		*result = cons( intern("quote"), cons(*result,NIL) );
		return err;
	case '`':
		state->cur++;
		err = _parse( state, result );
		if( err ) return err;
		*result = cons( intern("quasi-quote"), cons(*result,NIL) );
		return err;
	case ',':
		state->cur++;
		err = _parse( state, result );
		if( err ) return err;
		*result = cons( intern("unquote"), cons(*result,NIL) );
		return err;
	default:
		{
			char *end = state->cur+1;
			while( _is_val_char(*end) ) end++;
			*result = _parse_token( state->cur, end );
			state->cur = end;
			return 0;
		}
	}
	assert(0);
}

Value parse( char *src )
{
	ParseState state;
	state.src = src;
	state.cur = src;
	state.line = 0;
	Value val;
	int err = _parse( &state, &val );
	err = 0;
	return val;
}

Value parse_list( char *src )
{
	ParseState state;
	state.src = src;
	state.cur = src;
	state.line = 0;
	Value val;
	int err = _parse_list( &state, &val );
	err = 0;
	return val;
}

void register_cfunc( char *sym, CFunctionType type, CFunctionFunc func )
{
	CFunction* cfunc = lambda_new();
	assert( cfunc );
	cfunc->func = func;
	cfunc->type = type;
	bundle_define( bundle_cur, intern(sym), CFUNCTION2V(cfunc) );
}

//********************************************************
// Evaluatin
//********************************************************

Value call( CFunction *func, Value vals, bool as_macro )
{
	Bundle *bundle = bundle_new( func->bundle );
	Value args = func->args;
	for( int i=0; i<func->arity; ++i ){
		Value val;
		if( as_macro ){
			val = CAR(vals);
		}else{
			val = eval( CAR(vals) );
		}
		bundle_define( bundle, CAR(args), val );
		args = CDR(args);
		vals = CDR(vals);
	}
	Bundle *old_bundle = bundle_cur;
	bundle_cur = bundle;
	Value result = begin( func->body );
	bundle_cur = old_bundle;
	return result;
}

Value _macro_expand( Value v );

Value _macro_expand_args( Value v )
{
	if( v ){
		return cons( _macro_expand(CAR(v)), _macro_expand_args(CDR(v)) );
	}else{
		return v;
	}
}

Value _macro_expand( Value v )
{
	if( V_IS_CELL(v) ){
		Value car = CAR(v);
		if( V_IS_SYMBOL(car) ){
			Value lmd_val = eval(car);
			if( V_IS_CFUNCTION(lmd_val) ){
				CFunction *lmd = V2CFUNCTION(lmd_val);
				Value vals = CDR(v);
				switch( lmd->type ){
				case C_FUNCTION_TYPE_MACRO:
					return call( lmd, vals, true );
				case C_FUNCTION_TYPE_SPECIAL:
					if( car == intern("if") || car == intern("macro") || car == intern("define")){
						return cons( CAR(v), _macro_expand_args( CDR(v) ) );
					}else if( car == intern("lambda") ){
						return cons( CAR(v), cons( CDAR(v), _macro_expand_args( CDDR(v) ) ) );
					}else if( car == intern("quote") || car == intern("quasi-quote") || car == intern("unquote") ){
						return v;
					}else{
						assert(0);
					}
				default:
					break;
				}
			}
		}
		return cons( CAR(v), _macro_expand_args( CDR(v) ) );
	}else{
		return v;
	}
}

Value macro_expand( Value args )
{
	return _macro_expand( CAR(args) );
}

Value eval( Value v )
{
	switch( TYPE_OF(v) ){
	case TYPE_NIL:
	case TYPE_INT:
	case TYPE_CFUNCTION:
	case TYPE_BOOL:
		return v;
	case TYPE_SYMBOL:
		{
			Value val;
			bool found = bundle_find( bundle_cur, v, &val );
			if( !found ){
				display_val( "symbol not found: ", v );
				assert(0);
			}
			return val;
		}
	case TYPE_CELL:
		{
			Value car = eval(CAR(v));
			Value cdr = CDR(v);
			switch( TYPE_OF(car) ){
			case TYPE_CFUNCTION:
				{
					CFunction *func = V2CFUNCTION(car);
					switch( func->type ){
					case C_FUNCTION_TYPE_LAMBDA:
						return call( func, cdr, false );
					case C_FUNCTION_TYPE_MACRO:
						return eval( call( func, cdr, true ) );
					case C_FUNCTION_TYPE_FUNC:
						return func->func( eval_list(cdr) );
					case C_FUNCTION_TYPE_SPECIAL:
						return func->func( cdr );
					default:
						assert(0);
					}
				}
			default:
				assert(0);
			}
		}
	default:
		assert(0);
	}
	return NIL;
}

Value eval_list( Value v )
{
	if( v ){
		return cons( eval(CAR(v)), eval_list(CDR(v)) );
	}else{
		return NIL;
	}
}

Value begin( Value v )
{
	Value result;
	for( Value cur=v; cur != NIL; cur = CDR(cur) ){
		result = eval( CAR(cur) );
	}
	return result;
}

Value let( Value v )
{
	// display( v );
	Bundle *bundle = bundle_new( bundle_cur );
	for( Value cur=CAR(v); cur != NIL; cur = CDR(cur) ){
		Value sym = first(CAR(cur));
		Value val = eval( second(CAR(cur)) );
		bundle_define( bundle, sym, val );
	}
	Bundle *old_bundle = bundle_cur;
	bundle_cur = bundle;
	Value result = begin( CDR(v) );
	bundle_cur = old_bundle;
	return result;
}

Value lambda( Value v )
{
	CFunction *new_lambda = lambda_new();
	new_lambda->type = C_FUNCTION_TYPE_LAMBDA;
	new_lambda->args = first(v);
	new_lambda->arity = value_length( new_lambda->args );
	new_lambda->body = _macro_expand_args(CDR(v));
	new_lambda->bundle = bundle_cur;
	return CFUNCTION2V(new_lambda);
}

Value macro( Value v )
{
	CFunction *new_lambda = lambda_new();
	new_lambda->type = C_FUNCTION_TYPE_MACRO;
	new_lambda->args = first(v);
	new_lambda->arity = value_length( new_lambda->args );
	new_lambda->body = CDR(v);
	new_lambda->bundle = bundle_cur;
	return CFUNCTION2V(new_lambda);
}

static jmp_buf *_loop_env = NULL;

Value loop( Value args )
{
	jmp_buf env;
	jmp_buf *old_env = _loop_env;
	_loop_env = &env;
	int ret = setjmp( env );
	while( ret == 0 ){
		begin( args );
	}
	_loop_env = old_env;
	return NIL;
}

Value _break( Value args )
{
	assert( _loop_env );
	longjmp( *_loop_env, 1 );
	return NIL;
}

//********************************************************
// Gabage collect
//********************************************************

Value retained = NIL;

static void _mark_root()
{
	gc_mark( (void*)retained );
	gc_mark( (void*)bundle_cur );
}

Value release( Value v ){
	if( V_IS_POINTER(v) ){
		for( Value *cur=&retained; *cur; cur = &CDR(*cur) ){
			if( CAR(*cur) == v ){
				if( CDR(*cur) ){
					CAR(*cur) = CDAR(*cur);
					CDR(*cur) = CDDR(*cur);
				}else{
					*cur = NIL;
				}
				break;
			}
		}
	}
	return v;
}

void gc()
{
	gc_run();
}

// print backtrace
// See: http://expcodes.com/12895
// See: http://0xcc.net/blog/archives/000067.html
#include <execinfo.h>
static void handler(int sig) {
	void *array[10];
	size_t size;

	// get void*'s for all entries on the stack
	size = backtrace(array, 10);

	// print out all the frames to stderr
	fprintf(stderr, "Error: signal %d:\n", sig);
	backtrace_symbols_fd(array+3, size-3, 2/*=stderr*/);
	exit(1);
}

void init()
{
	gc_init( _mark_root );
	
	bundle_cur = bundle_new( NULL );

	signal( SIGABRT, handler );
	signal( SIGSEGV, handler );

	defspecial( "let", let );
	defspecial( "lambda", lambda );
	defspecial( "macro", macro );
	defspecial( "macro-expand", macro_expand );
	defspecial( "loop", loop );
	defspecial( "break", _break );
	
	defun( "gemsym", _gemsym );
	
	cfunc_init();
}

