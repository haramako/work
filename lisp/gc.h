#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	void (*mark)( void *p );
	void (*free)( void *p );
} gc_vtbl;

typedef struct gc_tag {
	int marked;
	struct gc_tag *next;
	gc_vtbl *vtbl;
} gc_tag;

void gc_init( void (*f)(void) );
void* gc_malloc( size_t size, gc_vtbl *vtbl );
void gc_mark( void *p );
void gc_run();
void gc_null( void *p );

#define GC_MALLOC( type ) (type*)gc_malloc(sizeof(type), &type##_vtbl );

#ifdef __cplusplus
}
#endif	
