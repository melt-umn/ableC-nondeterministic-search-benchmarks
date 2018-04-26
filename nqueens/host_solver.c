#include <state.h>
#include <solver.h>
#include <stdbool.h>
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

bool solve_help(state_t state, state_t *p_result, unsigned row) {
  while (true) {
    if (row >= get_size(state) - 1) {
      *p_result = state;
      return true;
    }
    if (!row_taken(state, row)) {
      break;
    }
    row++;
  }
  for (unsigned col = 0; col < get_size(state); col++) {
    if (!col_taken(state, col) && !diag_taken(state, row, col)) {
      move_t move = {row, col};
      state_t new_state = make_move(move, state);
      if (solve_help(new_state, p_result, row + 1)) {
        return true;
      } else {
        delete_state(new_state);
      }
    }
  }
  return false;
}

bool solve_host(state_t state, state_t *p_result) {
  return solve_help(state, p_result, 0);
}
