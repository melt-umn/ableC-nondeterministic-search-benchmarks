#include <solver.xh>
#include <search.xh>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

int main(unsigned argc, char *argv[]) {
  // (5, 1), (6, 0), (7, 4), (8, 0)
  int edge_size = 6;
  if (argc > 1) {
    edge_size = atoi(argv[1]);
  }
  if (edge_size < 1 || edge_size > 11) {
    fprintf(stderr, "Invalid edge size %d\n", edge_size);
    return 1;
  }
  int empty_pos = 0;
  if (argc > 2) {
    empty_pos = atoi(argv[2]);
  }
  if (empty_pos < 0 || empty_pos > edge_size * (edge_size - 1) / 2) {
    fprintf(stderr, "Invalid initial empty position %d\n", empty_pos);
    return 1;
  }
  state_t state = init_state(edge_size, empty_pos);
  print_state(state);
  
  int num_left = 1;
  if (argc > 3) {
    num_left = atoi(argv[3]);
  }
  if (num_left < 1) {
    fprintf(stderr, "Invalid # left %d\n", num_left);
    return 1;
  }

  char *driver = "seq";
  if (argc > 4) {
    driver = argv[4];
  }
  
  solution_t solution;
  bool success;
  if (!strcmp(driver, "seq")) {
    success = invoke(search_sequential, &solution, solve(state, num_left));
  } else if (!strcmp(driver, "spawn")) {
    int initial_depth = 5;
    if (argc > 5) {
      initial_depth = atoi(argv[5]);
    }
    if (initial_depth < 0) {
      fprintf(stderr, "Invalid initial depth %d\n", initial_depth);
      return 1;
    }
    int num_threads = 8;
    if (argc > 6) {
      num_threads = atoi(argv[6]);
    }
    if (num_threads < 1) {
      fprintf(stderr, "Invalid # of threads %d\n", num_threads);
      return 1;
    }
    success = invoke(search_parallel_spawn(initial_depth, num_threads), &solution, solve(state, num_left));
  } else {
    fprintf(stderr, "Invalid search driver %s\n", driver);
    return 1;
  }
  
  if (success) {
    printf("Found solution:\n");
    print_solution(state, solution);
    delete_solution(solution);
  } else {
    printf("No solution\n");
  }
}
