#include "lisp.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void eval_str( char *str )
{
	Value src = parse_list(str);
	display( src );
	begin(src);
}

int main( int argc, char **argv )
{
	init();
	
	eval_str("(display t)");
	eval_str("(display (+ 1 (- 3 -1)))");
	
	return 0;
}

