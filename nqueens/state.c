#include <state.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <pthread.h>
#include <math.h>
#include <assert.h>
#include <stdio.h>

#define INITIAL_FRAMES_CAPACITY 10

struct state_impl {
  pthread_mutex_t mutex;
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

static inline void do_move(move_t move, unsigned size, bool *occupied) {
  assert(move.row < size);
  assert(move.col < size);
  bool (*occupied_2d)[size] = (bool (*)[size])occupied;
  assert(!occupied_2d[move.row][move.col]);
  occupied_2d[move.row][move.col] = true;
}

static inline void undo_move(move_t move, unsigned size, bool *occupied) {
  assert(move.row < size);
  assert(move.col < size);
  bool (*occupied_2d)[size] = (bool (*)[size])occupied;
  assert(occupied_2d[move.row][move.col]);
  occupied_2d[move.row][move.col] = false;
}

/**
 * Get a state impl with its current state as the state at any past instance, copying the state impl
 * if needed.  Invariant: The given and returned state impls are both locked by the current thread.
 *
 * @param state_impl The state impl to from which to demand the index.
 * @param index The index to demand.
 * @return The given state impl or a copy, representing the state at the given index.
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
      malloc(sizeof(struct state_impl) + sizeof(bool) * state_impl->size * state_impl->size);
    pthread_mutex_init(&new_state_impl->mutex, NULL);
    pthread_mutex_lock(&new_state_impl->mutex);
    new_state_impl->num_refs = 1;
    new_state_impl->frames_size = index;
    new_state_impl->frames_capacity = state_impl->frames_capacity;
    new_state_impl->frames = malloc(sizeof(struct history_frame) * new_state_impl->frames_capacity);
    for (unsigned i = 0; i < index; i++) {
      new_state_impl->frames[i] = (struct history_frame){state_impl->frames[i].move, 0};
    }
    new_state_impl->size = state_impl->size;
    memcpy(new_state_impl->occupied, state_impl->occupied, sizeof(bool) * state_impl->size * state_impl->size);
    for (int i = state_impl->frames_size - 1; i >= (signed)index; i--) {
      undo_move(state_impl->frames[i].move, state_impl->size, new_state_impl->occupied);
    }
    pthread_mutex_unlock(&state_impl->mutex);
    return new_state_impl;
  }
}

/**
 * Remove a reference to the current state of a state impl, possibly deleting the state impl if no
 * references remain.  Invariant: The given state impl is locked by the current thread, and is
 * unlocked by this function.
 *
 * @param state_impl The state impl for which to remove a reference, which should be locked by the
 * current thread.
 */
static inline void remove_state_impl_ref(struct state_impl *state_impl) {
  state_impl->num_refs--;
  bool has_ref = false;
  if (state_impl->num_refs == 0) {
    // Look for a previous state with a reference
    for (int i = state_impl->frames_size - 1; i >= 0; i--) {
      if (state_impl->frames[i].num_refs > 0) {
        // If there is some previous previous state with a reference, backtrack to it
        state_impl->num_refs = state_impl->frames[i].num_refs;
        for (int j = state_impl->frames_size - 1; j >= i; j--) {
          undo_move(state_impl->frames[j].move, state_impl->size, state_impl->occupied);
        }
        state_impl->frames_size = i;
        has_ref = true;
        break;
      }
    }
  } else {
    has_ref = true;
  }

  pthread_mutex_unlock(&state_impl->mutex);
  if (!has_ref) {
    // If neither the current nor previous state has a reference, free the state impl
    pthread_mutex_destroy(&state_impl->mutex);
    free(state_impl->frames);
    free(state_impl);
  }
}

state_t init_state(unsigned size) {
  struct state_impl *state_impl = malloc(sizeof(struct state_impl) + sizeof(bool) * size * size);
  pthread_mutex_init(&state_impl->mutex, NULL);
  state_impl->num_refs = 1;
  state_impl->frames_size = 0;
  state_impl->frames_capacity = INITIAL_FRAMES_CAPACITY;
  state_impl->frames = malloc(sizeof(struct history_frame) * INITIAL_FRAMES_CAPACITY);
  state_impl->size = size;
  for (unsigned i = 0; i < size * size; i++) {
    state_impl->occupied[i] = false;
  }
  return (state_t){0, state_impl};
}

state_t copy_state(state_t state) {
  pthread_mutex_lock(&state.impl->mutex);
  struct state_impl *state_impl = demand_index(state.impl, state.index);
  state_t result = {state.index, state_impl};
  pthread_mutex_unlock(&state_impl->mutex);
  return result;
}

void delete_state(state_t state) {
  pthread_mutex_lock(&state.impl->mutex);
  assert(state.index <= state.impl->frames_size);
  if (state.index == state.impl->frames_size) {
    // We are deleting the most recent state
    remove_state_impl_ref(state.impl);
  } else {
    // We are deleting a state after which additional moves have been made
    state.impl->frames[state.index].num_refs--;
    pthread_mutex_unlock(&state.impl->mutex);
  }
}

state_t make_move(move_t move, state_t state) {
  pthread_mutex_lock(&state.impl->mutex);
  
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
  do_move(move, state_impl->size, state_impl->occupied);
  
  pthread_mutex_unlock(&state_impl->mutex);
  
  return (state_t){state.index + 1, state_impl};
}

bool is_occupied(state_t state, unsigned row, unsigned col) {
  unsigned size = state.impl->size;
  assert(row < size);
  assert(col < size);
  pthread_mutex_lock(&state.impl->mutex);
  struct state_impl *state_impl = demand_index(state.impl, state.index);
  bool result = ((bool (*)[size])state_impl->occupied)[row][col];
  remove_state_impl_ref(state_impl);
  return result;
}

unsigned get_size(state_t state) {
  return state.impl->size;
}

bool is_solved(state_t state) {
  return state.index == get_size(state); // Each move adds one queen
}
