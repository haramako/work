#ifndef __SYMBOL_H__
#define __SYMBOL_H__

#ifndef symbol_t
#define symbol_t unsigned int
#endif

#ifndef SYMBOL_SEED
#define SYMBOL_SEED 0x9e3779b9
#endif

namespace symbol {

  const size_t symbol_size = sizeof(symbol_t);

  inline symbol_t hash( symbol_t v1, symbol_t v2 )
  {
    return v1 ^ v2 + SYMBOL_SEED + (v1<<5) + (v1>>2);
  }

  template<size_t N>
    inline symbol_t sym(const symbol_t (&str)[N])
    {
      return hash( sym(reinterpret_cast<const symbol_t (&)[N-1]>(str)), str[N - 1] );
    }

  template<>
    inline symbol_t sym<1>(const symbol_t (&str)[1])
    {
      return hash(0,str[0]);
    }

  template <size_t N>
    inline symbol_t sym(const char (&str)[N])
    {
      return sym(reinterpret_cast<const symbol_t (&)[(N+symbol_size-1)/symbol_size]>(str));
    }
  
  inline symbol_t sym(const char *str)
  {
    char buf[symbol_size];
    for(int i=0; i<symbol_size; i++ ){
      if( str[i] == '\0' ){
        // string finished
        for(; i<symbol_size; i++ ) buf[i] = 0;
        return hash( 0, *reinterpret_cast<const symbol_t*>(buf) );
      }
      buf[i] = str[i];
    }
    // string does't finished
    return hash( sym(str+symbol_size), *reinterpret_cast<const symbol_t*>(str) );
  }
}

#endif // __SYMBOL_H__
