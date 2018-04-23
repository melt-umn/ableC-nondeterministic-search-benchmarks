#include <search.xh>
#include <stdio.h>
#include <stdbool.h>
#include <math.h>

// Factorization using Fermat’s method
search unsigned long factor(unsigned long n) {
  if (n % 2 == 0) {
    choice {
      succeed 2;
      choose succeed factor(n / 2);
    }
  } else {
    choose unsigned long a = ulrange((unsigned long)ceil(sqrt(n)), n);
    double b = sqrt(a * a - n);
    require b == floor(b);
    choice {
      succeed a - (unsigned long)b;
      succeed a + (unsigned long)b;
    }
  }
}

search unsigned long factor_exclusive(unsigned long n) {
  choose unsigned long f = factor(n);
  require f > 0;
  require f != n;
  succeed f;
}
