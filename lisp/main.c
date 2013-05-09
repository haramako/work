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

void mode_help()
{
	printf( "./clisp (help|test)\n" );
	exit(0);
}

void mode_test( int argc, char **argv )
{
	eval_str("(print t)");
	eval_str("(print (+ 1 (- 3 -1)))");
	exit(0);
}

void mode_run( int argc, char **argv )
{
	char *filename = argv[0];
	FILE *f = fopen( filename, "r" );
	if( !f ){
		printf( "cannot open %s\n", filename );
		exit(1);
	}
	char buf[8192];
	size_t len = fread( buf, 1, sizeof(buf), f );
	buf[len] = '\0';

	eval_str( buf );
	
	exit(0);
}


int main( int argc, char **argv )
{
	init();
	
	if( argc <= 1 ) mode_help();
	if( strcmp( argv[1], "help" ) == 0 ) {
		mode_help();
	}else if( strcmp( argv[1], "test" ) == 0 ) {
		mode_test( argc-2, argv+2 );
	}else{
		mode_run( argc-1, argv+1 );
	}

	/*
	Atom *hoge = atom_find( "hoge" );
	atom_find( "fuga" );
	atom_find( "piyo" );
	Atom *hoge2 = atom_find( "hoge" );	
	printf( "piyo %p %p %s\n", hoge, hoge2, hoge2->str );
	
	Value x;
	x = cons( INT2V(1), cons( INT2V(-2), ATOM2V(atom_find("nyan")) ) );
	// x = ATOM2V(atom_find("nyan"));
	// x = INT2V(1);
	printf( "hoge %ld %s\n", INT2V(1), value_to_str(x) );

	print_val( parse("10 '11") );

	print_val( name_find(ATOM2V(atom_find("print"))) );

	*/
	
	return 0;
}


