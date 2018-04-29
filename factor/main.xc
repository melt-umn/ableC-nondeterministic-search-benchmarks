#define _XOPEN_SOURCE
#define _XOPEN_SOURCE_EXTENDED

#include <factor.xh>
#include <search.xh>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <math.h>

unsigned long random_prime(unsigned long max) {
  unsigned long n;
  bool success;
  do {
    n = random() % max;
    if (n % 2) {
      success = true;
      for (unsigned long i = 3; i < sqrt(n); i += 2) {
        if (n % i == 0) {
          success = false;
          break;
        }
      }
    }
  } while (!success);
  return n;
}

int main(unsigned argc, char *argv[]) {
  // unsigned long max = 10000;
  // if (argc > 1) {
  //   max = atol(argv[1]);
  // }
  
  // unsigned long n = random_prime(max) * random_prime(max);
  unsigned long n = 21641161;
  if (argc > 1) {
    n = atol(argv[1]);
  }
  printf("Factoring %lu\n", n);

  char *driver = "seq";
  if (argc > 2) {
    driver = argv[2];
  }
  
  bool success;
  unsigned long result;
  if (!strcmp(driver, "dfs")) {
    success = invoke(search_sequential_dfs, &result, factor_exclusive(n));
  } else if (!strcmp(driver, "seq")) {
    int depth = 7;
    if (argc > 5) {
      depth = atoi(argv[3]);
    }
    if (depth < 0) {
      fprintf(stderr, "Invalid depth %d\n", depth);
      return 1;
    }
    success = invoke(search_sequential(depth), &result, factor_exclusive(n));
  } else if (!strcmp(driver, "spawn")) {
    int global_depth = 1;
    if (argc > 3) {
      global_depth = atoi(argv[3]);
    }
    if (global_depth < 0) {
      fprintf(stderr, "Invalid global depth %d\n", global_depth);
      return 1;
    }
    int thread_depth = 0;
    if (argc > 4) {
      thread_depth = atoi(argv[4]);
    }
    if (thread_depth < 0) {
      fprintf(stderr, "Invalid thread depth %d\n", thread_depth);
      return 1;
    }
    int num_threads = 8;
    if (argc > 5) {
      num_threads = atoi(argv[5]);
    }
    if (num_threads < 1) {
      fprintf(stderr, "Invalid # of threads %d\n", num_threads);
      return 1;
    }
    success = invoke(search_parallel_spawn(global_depth, thread_depth, num_threads),
                     &result, factor_exclusive(n));
  } else if (!strcmp(driver, "steal")) {
    int global_depth = 1;
    if (argc > 3) {
      global_depth = atoi(argv[3]);
    }
    if (global_depth < 0) {
      fprintf(stderr, "Invalid global depth %d\n", global_depth);
      return 1;
    }
    int thread_depth = 0;
    if (argc > 4) {
      thread_depth = atoi(argv[4]);
    }
    if (thread_depth < 0) {
      fprintf(stderr, "Invalid thread depth %d\n", thread_depth);
      return 1;
    }
    int num_threads = 8;
    if (argc > 5) {
      num_threads = atoi(argv[5]);
    }
    if (num_threads < 1) {
      fprintf(stderr, "Invalid # of threads %d\n", num_threads);
      return 1;
    }
    success = invoke(search_parallel_steal(global_depth, thread_depth, num_threads),
                     &result, factor_exclusive(n));
  } else {
    fprintf(stderr, "Invalid search driver %s\n", driver);
    return 1;
  }

  if (success) {
    printf("Result: %lu\n", result);
  } else {
    printf("Value is prime\n");
  }
}
