#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef void (*gcmarkfunc)( void* p );

typedef struct {
	int marked;
	void *next;
	gcmarkfunc marker;
} gc_tag;


gc_tag _guard;
int _color = 0;
gcmarkfunc _root_marker;


void gc_init( gcmarkfunc root_marker )
{
	_root_marker = root_marker;
	_guard.marked = -1;
	_guard.next = &_guard;
}

void* gc_malloc( size_t size, gcmarkfunc f )
{
	gc_tag *tag = (gc_tag*)malloc( size + sizeof(gc_tag) );
	tag->marker = f;
	tag->marked = -1;
	tag->next = _guard.next;
	_guard.next = tag;
	return ((char*)tag)+sizeof(gc_tag);
}

void gc_mark( void *p )
{
	if( !p ) return;
	
	gc_tag *tag = (gc_tag*)((char*)p - sizeof(gc_tag));
	if( tag->marked != _color ){
		printf( "mark %p\n", p );
		tag->marked = _color;
		if( tag->marker ) tag->marker( p );
	}
}

void gc_run()
{
	printf( "start gc\n" );
	_color = 1 - _color;

	// mark
	_root_marker(NULL);

	// sweep
	int all = 0, kill = 0;
	gc_tag *prev = &_guard;
	for(;;){
		gc_tag *cur = prev->next;
		if( cur == &_guard ) break;
		all++;

		if( cur->marked != _color ){
			printf( "sweep %p\n", cur );
			prev->next = cur->next;
			free( cur );
			kill++;
			continue;
		}
		
		prev = prev->next;
	}
	printf( "finish gc. %d - %d => %d\n", all, kill, all-kill );
}

typedef struct NodeTag
{
	struct NodeTag *left, *right;
} Node;

Node *n[5];

void mark_root( void *p )
{
	gc_mark( n[0] );
}

void node_marker( void *_p )
{
	Node *p = (Node*)_p;
	// fprintf( stderr, "%p %p %p\n", p, p->left, p->right );
	
	gc_mark( p->left );
	gc_mark( p->right );
}
		

int main( int argc, char **argv )
{
	gc_init( mark_root );

	n[0] = NULL;
	gc_run();
	
	int i;
	for( i=0; i<5; i++ ){
		n[i] = (Node*)gc_malloc( sizeof(Node), node_marker );
		n[i]->left = NULL;
		n[i]->right = NULL;
		printf( "N[%d] = %p\n", i, n[i] );
	}

	
	n[0]->left = n[1];
	n[1]->left = n[3];
	n[3]->left = n[2];
	n[3]->right = n[0];
	n[4]->left = n[3];

	gc_run();

	n[1]->left = NULL;
	
	gc_run();

	return 0;
}
