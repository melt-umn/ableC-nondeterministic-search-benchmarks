#ifndef _STATE_H
#define _STATE_H

typedef struct move {
  unsigned row, col;
} move_t;

typedef struct state {
  unsigned index;
  struct state_impl *impl;
} state_t;

state_t init_state(unsigned size);
state_t copy_state(state_t state);
void delete_state(state_t state);
state_t make_move(move_t move, state_t state);
_Bool is_occupied(state_t state, unsigned row, unsigned col);
unsigned get_size(state_t state);
_Bool is_solved(state_t state);

#endif
