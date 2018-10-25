#include <state.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#include <assert.h>
#include <stdio.h>

state_t init_state(uint8_t edge_size, uint8_t empty_pos) {
  uint8_t size = edge_size * (edge_size + 1) / 2;
  assert(size <= 64);
  return (state_t){size, size - 1, 0, ~(1ull << empty_pos)};
}

state_t make_move(move_t move, state_t state) {
  assert(move.from < state.size);
  assert(move.to < state.size);
  assert(move.removed < state.size);
  assert(state.occupied & 1ull << move.from);
  assert(!(state.occupied & 1ull << move.to));
  assert(state.occupied & 1ull << move.removed);
  uint64_t occupied = (state.occupied & ~(1ull << move.from | 1ull << move.removed)) | 1ull << move.to;
  return (state_t){state.size, state.num_occupied - 1, state.num_removed + 1, occupied};
}

bool is_occupied(state_t state, uint8_t pos) {
  return (state.occupied & 1ull << pos) != 0;
}

unsigned get_edge_size(state_t state) {
  return floor((sqrt(1 + 8 * state.size) - 1) / 2);
}
