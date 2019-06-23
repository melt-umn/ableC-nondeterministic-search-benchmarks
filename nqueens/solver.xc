#include <solver.xh>
#include <search.xh>
#include <refcount.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

search unsigned empty_row(state_t state) {
  choose unsigned row = urange(0, get_size(state));
  spawn;
  require !row_taken(state, row);
  succeed row;
}

search move_t valid_move(state_t state) {
  pick unsigned row = empty_row(state);
  choose unsigned col = urange(0, get_size(state));
  spawn;
  require !col_taken(state, col);
  require !diag_taken(state, row, col);
  succeed (move_t){row, col};
}

void finalize_state(void *p) {
  delete_state(*(state_t *)p);
}

search state_t solve_copy(state_t state) {
  if (is_solved(state)) {
    succeed state;
  } else {
    refcount_tag_t rt_state;
    struct state *p_state =
      refcount_final_malloc(sizeof(state_t), &rt_state, 0, NULL, finalize_state);
    *p_state = state;
    
    choose move_t move = valid_move(state)
      finally { remove_ref(rt_state); }
    rt_state;
    //print_move(move);
    state_t new_state = make_move(move, state);
    //print_state(new_state);
    
    choose succeed solve_copy(new_state);
  }
}

search state_t solve(state_t state) {
  choose succeed solve_copy(copy_state(state));
}
