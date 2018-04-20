#include <solver.xh>
#include <search.xh>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

int main(unsigned argc, char *argv[]) {
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
  default:
    fprintf(stderr, "Invalid option %d\n", option);
    return 1;
  }
  print_formula(f);

  char *driver = "seq";
  if (argc > 2) {
    driver = argv[2];
  }

  bool *assignment;
  bool success;
  if (!strcmp(driver, "seq")) {
    success = invoke(search_sequential, &assignment, solve(f));
  } else if (!strcmp(driver, "spawn")) {
    int initial_depth = 5;
    if (argc > 3) {
      initial_depth = atoi(argv[3]);
    }
    if (initial_depth < 0) {
      fprintf(stderr, "Invalid initial depth %d\n", initial_depth);
      return 1;
    }
    int num_threads = 8;
    if (argc > 4) {
      num_threads = atoi(argv[4]);
    }
    if (num_threads < 1) {
      fprintf(stderr, "Invalid # of threads %d\n", num_threads);
      return 1;
    }
    success = invoke(search_parallel_spawn(initial_depth, num_threads), &assignment, solve(f));
  } else if (!strcmp(driver, "steal")) {
    int num_threads = 8;
    if (argc > 3) {
      num_threads = atoi(argv[3]);
    }
    if (num_threads < 1) {
      fprintf(stderr, "Invalid # of threads %d\n", num_threads);
      return 1;
    }
    success = invoke(search_parallel_steal(num_threads), &assignment, solve(f));
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
