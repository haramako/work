#include <stdio.h>
#include <vector>
#include <list>
#include <algorithm>
#include <functional>
#include <iostream>

using namespace std;

typedef struct {
	int marked;
	void *next;
} gctag;

typedef void *gcmarkfunc( void* p );

gctag _gc_guard;

void* gc_malloc( size_t size, gcmarkfunc f )
{
	gctag *tag = (gctag*)malloc( size );
	tag->marked = -1;
	return ((char*)tag)+sizeof(gctag);
}

class Obj {
public:
	Obj *next;
	int marked;
	static Obj *bottom;
	static Obj *head;
	static Obj *root;
	static int flag;

	Obj(): next(NULL), marked(0) {
		if( !Obj::head ) Obj::head = this;
		if( Obj::bottom ) Obj::bottom->next = this;
		Obj::bottom = this;
	}
	virtual ~Obj(){}
	
	void mark(){
		if( marked != flag ){
			marked = flag;
			cout << "mark " << get_id() << endl;
			do_mark();
		}
	}

	virtual int get_id(){ return 0; }
	
	virtual void do_mark(){}

	static void gc()
	{
		cout << "start gc" << endl;
		// setup
		flag = 3 - flag;
		// mark
		root->mark();
		// sweep
		Obj* prev = NULL;
		for( Obj* cur = head; cur != NULL; cur = cur->next ){
			if( cur->marked != flag ){
				if( prev ) prev->next = cur->next;
				cout << "sweep " << cur->get_id() << endl;
				delete cur;
				cur = prev;
			}
			prev = cur;
		}
		
	}
};

class Node: public Obj {
 public:
	list<Node*> to;
	int id;

	Node(int _id): Obj(), id(_id) {};
	virtual ~Node(){};

	void add( Node *n )
	{
		to.push_back( n );
	}

	void remove( Node *n ){
		to.remove( n );
	}

	int get_id(){ return id; }

	void do_mark(){
		for( list<Node*>::iterator it = to.begin(); it != to.end(); ++it ){
			(*it)->mark();
		}
	}
	
};

Obj* Obj::bottom = NULL;
Obj* Obj::head = NULL;
Obj* Obj::root = NULL;
int Obj::flag = 1;

int main( int argc, char **argv )
{
	Node *n[5];
	for( int i=0; i<5; i++ ){
		n[i] = new Node(i);
	}

	Obj::root = n[0];
	n[0]->add(n[1]);
	n[1]->add(n[3]);
	n[3]->add(n[2]);
	n[3]->add(n[0]);
	n[4]->add(n[3]);

	Obj::gc();

	n[1]->remove( n[3] );
	
	Obj::gc();

	return 0;
}
