#include <stdio.h>
#include <stdlib.h>
#include <malloc/malloc.h>
#include <stdint.h>
#include "gc.h"

static gc_tag _guard;
static int _color = 0;
static void (*_root_mark)(void);
static void* _min_ptr;
static void* _max_ptr;
static gc_vtbl _auto_vtbl = { gc_mark_all, gc_null };

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

void *gc_new( size_t size )
{
	return gc_malloc( size, &_auto_vtbl );
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

	_min_ptr = (void*)UINTPTR_MAX;
	_max_ptr = 0;
	for(gc_tag *cur = _guard.next; cur != &_guard; cur = cur->next ){
		if( _min_ptr > (void*)cur ) _min_ptr = (void*)cur;
		if( _max_ptr < (void*)cur ) _max_ptr = (void*)cur;
	}
	_max_ptr += sizeof(gc_tag);
	
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

void gc_mark_all( void *p )
{
	void **tail = p + malloc_size(p-sizeof(gc_tag)) - sizeof(gc_tag);
	for( void **cur = (void**)p; cur < tail; cur++ ){
		if( *cur && (uintptr_t)*cur % sizeof(void*) == 0 && *cur >= _min_ptr && *cur <= _max_ptr ){
			gc_mark( (void*)*cur );
		}
	}
}

