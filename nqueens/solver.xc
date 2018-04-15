#include <solver.xh>
#include <search.xh>
#include <refcount.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <stdio.h>

bool row_taken(state_t state, unsigned row) {
  unsigned size = get_size(state);
  for (unsigned col = 0; col < size; col++) {
    if (is_occupied(state, row, col)) {
      return true;
    }
  }
  return false;
}

bool col_taken(state_t state, unsigned col) {
  unsigned size = get_size(state);
  for (unsigned row = 0; row < size; row++) {
    if (is_occupied(state, row, col)) {
      return true;
    }
  }
  return false;
}

bool diag_taken(state_t state, signed row, signed col) {
  unsigned size = get_size(state);
  for (signed i = 0; row + i < size && col + i < size; i++) {
    if (is_occupied(state, row + i, col + i)) {
      return true;
    }
  }
  for (signed i = 0; row + i < size && col - i >= 0; i++) {
    if (is_occupied(state, row + i, col - i)) {
      return true;
    }
  }
  for (signed i = 0; row - i >= 0 && col + i < size; i++) {
    if (is_occupied(state, row - i, col + i)) {
      return true;
    }
  }
  for (signed i = 0; row - i >= 0 && col - i >= 0; i++) {
    if (is_occupied(state, row - i, col - i)) {
      return true;
    }
  }
  return false;
}

search unsigned empty_row(state_t state) {
  choose unsigned row = urange(0, get_size(state));
  require !row_taken(state, row);
  succeed row;
}

search move_t valid_move(state_t state) {
  pick unsigned row = empty_row(state);
  choose unsigned col = urange(0, get_size(state));
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

void print_state(state_t state) {
  unsigned size = get_size(state);
  printf("   ");
  for (unsigned i = 0; i < size; i++) {
    printf(" %-2d", i);
  }
  printf("\n");
  for (unsigned i = 0; i < size; i++) {
    printf("%2d", i);
    for (unsigned j = 0; j < size; j++) {
      if (is_occupied(state, i, j)) {
        printf("  ♛");
      } else {
        printf("  .");
      }
    }
    printf("\n");
  }
}

void print_move(move_t move) {
  printf("%d,%d\n", move.row, move.col);
}