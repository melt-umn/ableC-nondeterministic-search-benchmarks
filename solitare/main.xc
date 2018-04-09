#include <solitare.xh>
#include <search.xh>

int main() {
  //state_t state = init_state(5, 1);
  state_t state = init_state(6, 0);
  //print_state(state);
  solution_t solution;
  if (invoke(search_sequential, &solution, solve(state))) {
    print_solution(state, solution);
  } else {
    printf("Failure\n");
  }
}
