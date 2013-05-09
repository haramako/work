#include "lisp.h"
#include <stdio.h>

static Value _progn( Value args )
{
	Value result;
	for( Value cur = args; cur != NIL; cur = CDR(cur) ){
		result = eval( CAR(cur) );
	}
	return result;
}

static Value _setq( Value args )
{
	Value atom = CAR(args);
	Value val = eval( CAR(CDR(args)) );
	name_add( atom, val );
	return NIL;
}

static Value _if( Value args )
{
	Value cond = eval( CAR(args) );
	if( cond ){
		return eval( CAR(CDR(args)) );
	}else{
		return progn( CDR(CDR(args)) );
	}
}

static Value _quote( Value args )
{
	return CAR(args);
}

static Value _print( Value args )
{
	for( Value cur = args; cur != NIL; cur = CDR(cur) ){
		char buf[1024];
		value_to_str(buf, CAR(cur));
		printf( "%s ", buf );
	}
	printf( "\n" );
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

void cfunc_init()
{
	defspecial( "progn", _progn );
	defspecial( "setq", _setq );
	defspecial( "if", _if );
	defspecial( "quote", _quote );
	
	defun( "print", _print );
	defun( "+", _add );
	defun( "-", _sub );

}
