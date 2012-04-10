#ifdef __RANKED_STORE_H__
#define __RANKED_STORE_H__

enum RANKING_TYPE {
  RANKING_TYPE_INT4 = 0,
  RANKING_TYPE_INT8,
  RANKING_TYPE_FLOAT,
  RANKING_TYPE_DOUBLE,
  RANKING_TYPE_STRING
}

typedef struct {
  
} ranking_t;

ranking_t* ranking_init(void);


#endif
