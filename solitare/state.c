#include <state.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <assert.h>
#include <stdio.h>

#define INITIAL_FRAMES_CAPACITY 10

struct state_impl {
  unsigned num_refs;
  unsigned frames_size;
  unsigned frames_capacity;
  struct history_frame {
    move_t move;
    unsigned num_refs;
  } *frames;
  unsigned size;
  bool occupied[];
};

static inline void do_move(move_t move, bool *occupied) {
  assert(occupied[move.from]);
  assert(!occupied[move.to]);
  assert(occupied[move.removed]);
  occupied[move.to] = true;
  occupied[move.from] = false;
  occupied[move.removed] = false;
}

static inline void undo_move(move_t move, bool *occupied) {
  assert(!occupied[move.from]);
  assert(occupied[move.to]);
  assert(!occupied[move.removed]);
  occupied[move.to] = false;
  occupied[move.from] = true;
  occupied[move.removed] = true;
}

/**
 * Get a state impl with its current state as the state at any past instance, copying the state impl
 * if needed.
 */
static inline struct state_impl *demand_index(struct state_impl *state_impl, unsigned index) {
  assert(index <= state_impl->frames_size);
  if (index == state_impl->frames_size) {
    // We are demanding the most recent state, so the current state impl will do
    state_impl->num_refs++;
    return state_impl;
  } else {
    // We are demanding a previous state - copy the state impl and backtrack to the requested state
    assert(state_impl->frames[index].num_refs > 0);
    struct state_impl *new_state_impl =
      malloc(sizeof(struct state_impl) + sizeof(bool) * state_impl->size);
    new_state_impl->num_refs = 1;
    new_state_impl->frames_size = index;
    new_state_impl->frames_capacity = state_impl->frames_capacity;
    new_state_impl->frames = malloc(sizeof(struct history_frame) * new_state_impl->frames_capacity);
    for (unsigned i = 0; i < index; i++) {
      new_state_impl->frames[i] = (struct history_frame){state_impl->frames[i].move, 0};
    }
    new_state_impl->size = state_impl->size;
    memcpy(new_state_impl->occupied, state_impl->occupied, sizeof(bool) * state_impl->size);
    for (int i = state_impl->frames_size - 1; i >= (signed)index; i--) {
      undo_move(state_impl->frames[i].move, new_state_impl->occupied);
    }
    return new_state_impl;
  }
}

/**
 * Remove a reference to the current state of a state impl, possibly deleting the state impl if no
 * references remain.
 */
static inline void remove_state_impl_ref(struct state_impl *state_impl) {
  state_impl->num_refs--;
  if (state_impl->num_refs == 0) {
    // Look for a previous state with a reference
    for (int i = state_impl->frames_size - 1; i >= 0; i--) {
      if (state_impl->frames[i].num_refs > 0) {
        // If there is some previous previous state with a reference, backtrack to it
        state_impl->num_refs = state_impl->frames[i].num_refs;
        for (int j = state_impl->frames_size - 1; j >= i; j--) {
          undo_move(state_impl->frames[i].move, state_impl->occupied);
        }
        state_impl->frames_size = i;
        return;
      }
    }
    // If no previous state has a reference, free the state impl
    free(state_impl->frames);
    free(state_impl);
  }
}

state_t init_state(unsigned edge_size, unsigned empty) {
  unsigned size = edge_size * (edge_size - 1) / 2;
  struct state_impl *state_impl = malloc(sizeof(struct state_impl) + sizeof(bool) * size);
  state_impl->num_refs = 1;
  state_impl->frames_size = 0;
  state_impl->frames_capacity = INITIAL_FRAMES_CAPACITY;
  state_impl->frames = malloc(sizeof(struct history_frame) * INITIAL_FRAMES_CAPACITY);
  state_impl->size = size;
  for (unsigned i = 0; i < size; i++) {
    state_impl->occupied[i] = true;
  }
  state_impl->occupied[empty] = false;
  return (state_t){0, state_impl};
}

state_t copy_state(state_t state) {
  return (state_t){state.index, demand_index(state.impl, state.index)};
}

void delete_state(state_t state) {
  assert(state.index <= state.impl->frames_size);
  if (state.index == state.impl->frames_size) {
    // We are deleting the most recent state
    remove_state_impl_ref(state.impl);
  } else {
    // We are deleting a state after which additional moves have been made
    state.impl->frames[state.index].num_refs--;
  }
}

bool is_solved(state_t state) {
  return state.index == state.impl->size - 2; // Each move removes one peg
}

bool is_occupied(state_t state, unsigned loc) {
  struct state_impl *state_impl = demand_index(state.impl, state.index);
  bool result = state_impl->occupied[loc];
  remove_state_impl_ref(state_impl);
  return result;
}

unsigned get_size(state_t state) {
  return state.impl->size;
}

unsigned get_edge_size(state_t state) {
  return floor((sqrt(1 + 8 * get_size(state)) - 1) / 2);
}

state_t make_move(move_t move, state_t state) {
  // Get a state impl representing the current state
  struct state_impl *state_impl = demand_index(state.impl, state.index);

  // Expand the frame stack if it has insufficient capacity
  assert(state_impl->frames_capacity >= state_impl->frames_size);
  if (state_impl->frames_capacity == state_impl->frames_size) {
    state_impl->frames_capacity *= 2;
    state_impl->frames =
      realloc(state_impl->frames, sizeof(struct history_frame) * state_impl->frames_capacity);
  }

  // Perform and record the move
  state_impl->frames_size++;
  state_impl->frames[state.index] = (struct history_frame){move, state_impl->num_refs - 1};
  state_impl->num_refs = 1;
  do_move(move, state_impl->occupied);
  return (state_t){state.index + 1, state_impl};
}
