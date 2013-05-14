#include "lisp.h"
#include <stdio.h>
#include <string.h>

static Value _define( Value args )
{
	Value atom = CAR(args);
	Value val = eval( CAR(CDR(args)) );
	bundle_define( bundle_cur, atom, val );
	return NIL;
}

static Value _set_i( Value args )
{
	Value atom = CAR(args);
	Value val = eval( CAR(CDR(args)) );
	bundle_set( bundle_cur, atom, val );
	return NIL;
}

static Value _if( Value args )
{
	Value cond = eval( CAR(args) );
	if( cond != VALUE_F ){
		return eval( CAR(CDR(args)) );
	}else{
		return begin( CDR(CDR(args)) );
	}
}

static Value _quote( Value args )
{
	return CAR(args);
}

static Value _quasi_quote_inner( Value args )
{
	switch( TYPE_OF(args) ){
	case TYPE_CELL:
		if( CAR(args) == intern("unquote") ){
			return eval( CAR( CDR(args) ) );
		}else{
			return cons( _quasi_quote_inner(CAR(args)), _quasi_quote_inner(CDR(args)) );
		}
	default:
		return args;
	}
}

static Value _quasi_quote( Value args )
{
	return _quasi_quote_inner( CAR(args) );
}

void display_val( char* str, Value args )
{
	char buf[1024];
	value_to_str(buf, args);
	printf( "%s%s\n", str, buf );
}

Value display( Value args )
{
	char buf[1024];
	value_to_str(buf, args);
	if( V_IS_CELL(args) ){
		buf[ strlen(buf) - 1 ] = '\0';
		printf( "%s\n", buf+1 );
	}else{
		printf( "%s\n", buf );
	}
	return args;
}

static Value _add( Value args )
{
	int sum = 0;
	for( Value cur = args; cur != NIL; cur = CDR(cur) ){
		sum += V2INT(CAR(cur));
	}
	return INT2V(sum);
}

static Value _sub( Value args )
{
	int sum = V2INT(CAR(args));
	for( Value cur = CDR(args); cur != NIL; cur = CDR(cur) ){
		sum -= V2INT(CAR(cur));
	}
	return INT2V(sum);
}

static Value eq_p( Value args )
{
	return ( first(args) == second(args) )?VALUE_T:VALUE_F;
}

static Value _car( Value args )
{
	return CAR(first(args));
}

static Value _cdr( Value args )
{
	return CDR(first(args));
}

void cfunc_init()
{
	defspecial( "begin", begin );
	defspecial( "define", _define );
	defspecial( "set!", _set_i );
	defspecial( "if", _if );
	defspecial( "quote", _quote );
	defspecial( "quasi-quote", _quasi_quote );
	
	defun( "display", display );
	defun( "+", _add );
	defun( "-", _sub );
	defun( "eq?", eq_p );
	defun( "car", _car );
	defun( "cdr", _cdr );

}
