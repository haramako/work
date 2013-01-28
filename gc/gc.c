#include <stdio.h>
#include <stdlib.h>
#include <malloc/malloc.h>
#include <stdint.h>
#include "gc.h"

static gc_tag _guard;
static int _color = 0;
static void (*_root_mark)(void);

void gc_init( void (*f)(void) )
{
	_root_mark = f;
	_guard.marked = -1;
	_guard.next = &_guard;
}

void* gc_malloc( size_t size, gc_vtbl *vtbl )
{
	gc_tag *tag = malloc( size + sizeof(gc_tag) );
	tag->marked = -1;
	tag->vtbl = vtbl;
	tag->next = _guard.next;
	_guard.next = tag;
	return ((char*)tag)+sizeof(gc_tag);
}

void gc_mark( void *p )
{
	if( !p ) return;
	
	gc_tag *tag = (gc_tag*)((char*)p - sizeof(gc_tag));
	if( tag->marked != _color ){
		// printf( "mark %p\n", p );
		tag->marked = _color;
		tag->vtbl->mark( p );
	}
}

void gc_run()
{
	// init
	// printf( "start gc\n" );
	_color = 1 - _color;

	// mark
	_root_mark();

	// sweep
	int all = 0, kill = 0;
	gc_tag *prev = &_guard;
	for(;;){
		gc_tag *cur = prev->next;
		if( cur == &_guard ) break;
		all++;

		if( cur->marked != _color ){
			// printf( "sweep %p\n", cur );
			prev->next = cur->next;
			cur->vtbl->free( (char*)cur+sizeof(gc_tag) );
			free( cur );
			kill++;
			continue;
		}
		
		prev = prev->next;
	}
	printf( "finish gc. %d - %d => %d\n", all, kill, all-kill );
}


void gc_null( void *p ){}
