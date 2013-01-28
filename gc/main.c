#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc/malloc.h>

#include "gc.h"

typedef struct NodeTag
{
	struct NodeTag *left, *right;
	int id;
	int show;
} Node;

Node *root = NULL;

void mark_root()
{
	gc_mark( root );
}

void node_mark( void *_p )
{
	Node *p = _p;
	gc_mark( p->left );
	gc_mark( p->right );
	printf( "mark %d\n", p->id );
}

void node_free( void *_p )
{
	Node *p = _p;
	printf( "free %d\n", p->id );
}

gc_vtbl Node_vtbl = { node_mark, node_free };

#define MAX 100

void show_node( Node *n, int show )
{
	if( !n ) return;
	
	if( n->show != show ){
		n->show = show;
		int left = 0, right = 0;
		if( n->left ) left = n->left->id;
		if( n->right ) right = n->right->id;
		printf( "%d->[%d,%d]\n", n->id, left, right );
		show_node( n->left, show );
		show_node( n->right, show );
	}
}

void show_node_all( Node *n )
{
	static int show = 0;
	show++;
	show_node( n, show );
}

int main( int argc, char **argv )
{
	gc_init( mark_root );
	gc_run();
	
	Node *n[MAX];
	
	int i;
	for( i=0; i<MAX; i++ ){
		n[i] = GC_MALLOC( Node );
		n[i]->left = NULL;
		n[i]->right = NULL;
		n[i]->id = i;
		n[i]->show = 0;
		// printf( "N[%d] = %p\n", i, n[i] );
	}
	root = n[0];
	show_node_all( root );

	for( i=0; i<MAX; i++ ){
		n[i]->left = n[rand()%MAX];
		n[i]->right = n[rand()%MAX];
	}
	show_node_all( root );
	
	gc_run();

	n[0]->left = NULL;
	
	gc_run();

	return 0;
}
