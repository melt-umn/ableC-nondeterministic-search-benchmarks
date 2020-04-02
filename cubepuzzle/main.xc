#include <solver.xh>
#include <search.xh>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

int main(unsigned argc, char *argv[]) {
  int pieces = 25;
  if (argc > 1) {
    pieces = atoi(argv[1]);
  }
  
  char *driver = "share";
  if (argc > 2) {
    driver = argv[2];
  }
  
  vector<state_t> solution;
  bool success;
  if (!strcmp(driver, "dfs")) {
    success = invoke(search_sequential_dfs, &solution, solve(pieces));
  } else if (!strcmp(driver, "seq")) {
    int depth = 2;
    if (argc > 3) {
      depth = atoi(argv[3]);
    }
    if (depth < 0) {
      fprintf(stderr, "Invalid depth %d\n", depth);
      return 1;
    }
    success = invoke(search_sequential(depth), &solution, solve(pieces));
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
                     &solution, solve(pieces));
  } else if (!strcmp(driver, "share")) {
    int global_depth = 0;
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
                     &solution, solve(pieces));
  } else {
    fprintf(stderr, "Invalid search driver %s\n", driver);
    return 1;
  }
  
  if (success) {
    printf("Found solution:\n");
    state_t complete = 0;
    for (unsigned i = 0; i < solution.size; i++) {
      printf("Move %d\n", i);
      print_state(solution[i]);
      complete |= solution[i];
    }
    printf("Complete box\n");
    print_state(complete);
  } else {
    printf("No solution\n");
  }
}
