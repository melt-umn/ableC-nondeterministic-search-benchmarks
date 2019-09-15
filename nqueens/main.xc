#include <solver.xh>
#include <search.xh>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

int main(unsigned argc, char *argv[]) {
  srand(12345);
  
  int size = 6;
  if (argc > 1) {
    size = atoi(argv[1]);
  }
  if (size < 1) {
    fprintf(stderr, "Invalid size %d\n", size);
    return 1;
  }
  state_t state = init_state(size);
  int num_initial = 2;
  if (argc > 2) {
    num_initial = atoi(argv[2]);
  }
  if (num_initial < 0 || num_initial > size) {
    fprintf(stderr, "Invalid number of initial queens %d\n", num_initial);
    return 1;
  }
  for (unsigned i = 0; i < num_initial; i++) {
    unsigned row, col;
    do {
      do {
        row = rand() % size;
      } while (row_taken(state, row));
      do {
        col = rand() % size;
      } while (col_taken(state, col));
    } while (diag_taken(state, row, col));
    state_t old_state = state;
    state = make_move((move_t){row, col}, state);
    delete_state(old_state);
  }
  print_state(state);
  
  char *driver = "share";
  if (argc > 3) {
    driver = argv[3];
  }
  
  state_t solution;
  bool success;
  if (!strcmp(driver, "host")) {
    success = solve_host(state, &solution);
  } else if (!strcmp(driver, "dfs")) {
    success = invoke(search_sequential_dfs, &solution, solve(state));
  } else if (!strcmp(driver, "seq")) {
    int depth = 2;
    if (argc > 4) {
      depth = atoi(argv[4]);
    }
    if (depth < 0) {
      fprintf(stderr, "Invalid depth %d\n", depth);
      return 1;
    }
    success = invoke(search_sequential(depth), &solution, solve(state));
  } else if (!strcmp(driver, "spawn")) {
    int global_depth = 2;
    if (argc > 4) {
      global_depth = atoi(argv[4]);
    }
    if (global_depth < 0) {
      fprintf(stderr, "Invalid global depth %d\n", global_depth);
      return 1;
    }
    int thread_depth = 0;
    if (argc > 5) {
      thread_depth = atoi(argv[5]);
    }
    if (thread_depth < 0) {
      fprintf(stderr, "Invalid thread depth %d\n", thread_depth);
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
    success = invoke(search_parallel_spawn(global_depth, thread_depth, num_threads),
                     &solution, solve(state));
  } else if (!strcmp(driver, "share")) {
    int global_depth = 2;
    if (argc > 4) {
      global_depth = atoi(argv[4]);
    }
    if (global_depth < 0) {
      fprintf(stderr, "Invalid global depth %d\n", global_depth);
      return 1;
    }
    int thread_depth = 0;
    if (argc > 5) {
      thread_depth = atoi(argv[5]);
    }
    if (thread_depth < 0) {
      fprintf(stderr, "Invalid thread depth %d\n", thread_depth);
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
    success = invoke(search_parallel_share(global_depth, thread_depth, num_threads),
                     &solution, solve(state));
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
