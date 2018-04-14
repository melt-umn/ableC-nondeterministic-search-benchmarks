#include <solver.xh>
#include <search.xh>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

int main(unsigned argc, char *argv[]) {
  int size = 6;
  if (argc > 1) {
    size = atoi(argv[1]);
  }
  if (size < 1) {
    fprintf(stderr, "Invalid size %d\n", size);
    return 1;
  }
  state_t state = init_state(size);
  //print_state(state);

  char *driver = "seq";
  if (argc > 2) {
    driver = argv[2];
  }
  
  state_t solution;
  bool success;
  if (!strcmp(driver, "seq")) {
    success = invoke(search_sequential, &solution, solve(state));
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
    success = invoke(search_parallel_spawn(initial_depth, num_threads), &solution, solve(state));
  } else {
    fprintf(stderr, "Invalid search driver %s\n", driver);
    return 1;
  }
  
  if (success) {
    printf("Found solution:\n");
    print_state(solution);
    delete_state(solution);
  } else {
    printf("No solution\n");
  }
  delete_state(state);
}
