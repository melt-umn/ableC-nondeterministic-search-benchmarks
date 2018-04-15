#include <stdint.h>

#ifndef _STATE_H
#define _STATE_H

typedef struct move {
  unsigned from, to, removed;
} move_t;

typedef struct state {
  uint8_t size, num_occupied;
  uint64_t occupied;
} state_t;

state_t init_state(uint8_t edge_size, uint8_t empty_pos);
state_t make_move(move_t move, state_t state);
_Bool is_occupied(state_t state, uint8_t pos);
unsigned get_edge_size(state_t state);

#endif
