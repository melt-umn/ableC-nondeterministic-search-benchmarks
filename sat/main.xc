#include <solver.xh>
#include <search.xh>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

//#define HARDCODED_TESTS

int main(unsigned argc, char *argv[]) {
#ifdef HARDCODED_TESTS
  int option = 0;
  if (argc > 1) {
    option = atoi(argv[1]);
  }
  formula_t f;
  switch (option) {
  case 0:
    f = formula(4, 5,
                clause(2, literal(false, 0), literal(true, 1)),
                clause(2, literal(false, 1), literal(true, 2)),
                clause(2, literal(false, 2), literal(true, 3)),
                clause(2, literal(false, 3), literal(true, 0)),
                clause(1, literal(false, 0)));
    break;
  case 1:
    f = formula(3, 8,
                clause(3, literal(true, 0), literal(false, 1), literal(false, 2)),
                clause(3, literal(true, 0), literal(false, 1), literal(true, 2)),
                clause(3, literal(true, 0), literal(true, 1), literal(false, 2)),
                clause(3, literal(true, 0), literal(true, 1), literal(true, 2)),
                clause(3, literal(false, 0), literal(false, 1), literal(false, 2)),
                clause(3, literal(false, 0), literal(false, 1), literal(true, 2)),
                clause(3, literal(false, 0), literal(true, 1), literal(false, 2)),
                clause(3, literal(false, 0), literal(true, 1), literal(true, 2)));
    break;
  case 2:
    f = formula(1, 1,
                clause(2, literal(true, 0), literal(false, 0)));
    break;
  case 3:
    f = formula(1, 2,
                clause(1, literal(true, 0)),
                clause(1, literal(false, 0)));
    break;
  case 4:
    f = formula(3, 4,
                clause(2, literal(false, 0), literal(false, 3)),
                clause(2, literal(true, 0), literal(false, 1)),
                clause(3, literal(false, 0), literal(true, 1), literal(false, 2)),
                clause(3, literal(true, 0), literal(false, 1), literal(true, 2)));
    break;
  default:
    fprintf(stderr, "Invalid option %d\n", option);
    return 1;
  }

#else
  char *filename;
  if (argc > 1) {
    filename = argv[1];
  } else {
    fprintf(stderr, "Expected a filename to load\n");
    exit(1);
  }
  formula_t f = load_formula(filename);
#endif
  
  print_formula(f);

  char *driver = "spawn";
  if (argc > 2) {
    driver = argv[2];
  }

  bool *assignment;
  bool success;
  if (!strcmp(driver, "dfs")) {
    success = invoke(search_sequential_dfs, &assignment, solve(f));
  } else if (!strcmp(driver, "seq")) {
    int depth = 7;
    if (argc > 5) {
      depth = atoi(argv[3]);
    }
    if (depth < 0) {
      fprintf(stderr, "Invalid depth %d\n", depth);
      return 1;
    }
    success = invoke(search_sequential(depth), &assignment, solve(f));
  } else if (!strcmp(driver, "spawn")) {
    int global_depth = 10;
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
                     &assignment, solve(f));
  } else if (!strcmp(driver, "share")) {
    int global_depth = 3;
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
    success = invoke(search_parallel_share(global_depth, thread_depth, num_threads),
                     &assignment, solve(f));
  } else {
    fprintf(stderr, "Invalid search driver %s\n", driver);
    return 1;
  }
  
  if (success) {
    printf("Found solution:\n");
    for (size_t i = 0; i < f.num_vars; i++) {
      printf("a%lu: %s\n", i, assignment[i]? "true" : "false");
    }
    free(assignment);
  } else {
    printf("No solution\n");
  }
  delete_formula(f);
}
