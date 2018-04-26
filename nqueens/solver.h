#include <state.h>

#ifndef _SOLVER_H
#define _SOLVER_H

_Bool row_taken(state_t state, unsigned row);
_Bool col_taken(state_t state, unsigned col);
_Bool diag_taken(state_t state, signed row, signed col);

void print_state(state_t state);
void print_move(move_t move);

_Bool solve_host(state_t state, state_t *p_result);

#endif
