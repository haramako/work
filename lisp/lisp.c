#include "lisp.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

Value cons( Value car, Value cdr )
{
	Cell *new_cell = malloc(sizeof(Cell));
	if( !new_cell ) assert(0);
	new_cell->car = car;
	new_cell->cdr = cdr;
	return (Value)new_cell;
}

size_t value_to_str( char *buf, Value v )
{
	char *orig_buf = buf;
	// printf( "%d\n", TYPE_OF(v) );
	switch( TYPE_OF(v) ){
	case TYPE_NIL:
		buf += sprintf( buf, "nil" );
		break;
	case TYPE_T:
		buf += sprintf( buf, "t" );
		break;
	case TYPE_INT:
		buf += sprintf( buf, "%d", V2INT(v) );
		break;
	case TYPE_ATOM:
		buf += sprintf( buf, "%s", V2ATOM(v)->str );
		break;
	case TYPE_CFUNCTION:
		buf += sprintf( buf, "(CFUNCTION:%p)", V2CFUNCTION(v) );
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
			case TYPE_INT:
			case TYPE_ATOM:
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

static Atom *_atom_root = NULL;

Atom* atom_find( const char *str )
{
	for( Atom *cur = _atom_root; cur != NULL; cur = cur->next ){
		if( strcmp( cur->str, str ) == 0 ) return cur;
	}
	// not found, create new atom
	Atom *new_atom = malloc( sizeof(Atom) );
	assert( new_atom );
	new_atom->str = malloc( strlen(str)+1 );
	assert( new_atom->str );
	strcpy( new_atom->str, str );
	new_atom->next = _atom_root;
	_atom_root = new_atom;
	return new_atom;
}

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
		return ATOM2V( atom_find( tmp ) );
	}
}

int _parse( ParseState *state, Value *result )
{
	int err;
	char c;
	_skip_space( state );
	while( (c = *state->cur) ){
		switch( c ){
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
		case '\'':
			state->cur++;
			err = _parse( state, result );
			if( err ) return err;
			*result = cons( ATOM2V(atom_find("quote")), cons(*result,NIL) );
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
		state->cur++;
	}
	return 0;
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
	CFunction* cfunc = malloc( sizeof(CFunction) );
	assert( cfunc );
	cfunc->func = func;
	cfunc->type = type;
	name_add( ATOM2V(atom_find(sym)), CFUNCTION2V(cfunc) );
}

static NameEntry *_name_root = NULL;

Value name_find( Value name )
{
	for( NameEntry *cur = _name_root; cur != NULL; cur = cur->next ){
		if( cur->name == name ) return cur->val;
	}
	return NIL;
}

void name_add( Value name, Value v )
{
	for( NameEntry *cur = _name_root; cur != NULL; cur = cur->next ){
		if( cur->val == v ){
			cur->val = v;
			return;
		}
	}
	// not found, create new atom
	NameEntry *new_entry = malloc( sizeof(NameEntry) );
	assert( new_entry );
	new_entry->name = name;
	new_entry->val = v;
	new_entry->next = _name_root;
	_name_root = new_entry;
}

Value _atom_progn;

Value eval( Value v )
{
	switch( TYPE_OF(v) ){
	case TYPE_NIL:
	case TYPE_INT:
	case TYPE_CFUNCTION:
	case TYPE_T:
		return v;
	case TYPE_ATOM:
		return name_find(v);
	case TYPE_CELL:
		{
			Value car = eval(CAR(v));
			Value cdr = CDR(v);
			switch( TYPE_OF(car) ){
			case TYPE_CFUNCTION:
				{
					CFunction *func = V2CFUNCTION(car);
					switch( func->type ){
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
	if( V_IS_CELL(v) ){
		return cons( eval(CAR(v)), eval_list(CDR(v)) );
	}else{
		return eval(v);
	}
}

Value progn( Value v )
{
	Value result;
	for( Value cur=v; cur != NIL; cur = CDR(cur) ){
		result = eval( CAR(cur) );
	}
	return result;
}

void init()
{
	_atom_root = NULL;
	_name_root = NULL;

	name_add( intern("t"), VALUE_T );

	cfunc_init();
}
