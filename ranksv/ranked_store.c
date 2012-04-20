#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <pthread.h>

#include "ranked_store.h"


typedef struct {
  int record_id;
} record_t;

typedef struct {
} index_t;

typedef struct {
  int id;
} leaf_t;

typedef struct {
  int id;
  int id;
} node_t;

#define REC_ID(rec) ((rec)->record_id)
#define REC_VAL(rec,type,offset) (*(type*)((char*)(rec)+sizeof(int)+(offset)))

#define LEAF_ID(leaf) ((leaf)->id)
#define LEAF_VAL(leaf,type) (*(type*)((char*)(leaf)+sizeof(int)))

int main( int argc, char **argv )
{
  record_t rec;
  REC_ID(&rec);
  int x = REC_VAL(&rec,int,100);
  leaf_t leaf;
  LEAF_ID(&leaf);
  LEAF_VAL(&leaf,int);
  return 0;
}
