#include <stdio.h>
#include "symbol.h"

using symbol::sym;

#if 1
int x[] = {
         sym("hoge_fuga_puge") };
#endif

int main( int argc, char **argv )
{
  char line[9999];
  //printf( "0x%08x\n", sym("/0/2/Messages/20676.emlx") );
  while( gets(line) ){
    printf( "0x%08llx %s\n", (unsigned long long)sym((char*)line), line );
    //printf( "0x%08llx\n", (unsigned long long)sym((char*)line) );
  }
  return 0;
}
