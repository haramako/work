#include "lisp.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void print_val( Value v )
{
	char buf[1024];
	value_to_str(buf,v);
	printf( "%s\n", buf );
}

void eval_str( char *str )
{
	Value src = parse_list(str);
	print_val( src );
	progn(src);
}

int main( int argc, char **argv )
{
	init();
	
	eval_str("(print t)");
	eval_str("(print (+ 1 (- 3 -1)))");
	exit(0);
	
	return 0;
}

