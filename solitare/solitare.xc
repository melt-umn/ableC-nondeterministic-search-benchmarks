#include <solitare.xh>
#include <refcount.h>
#include <stdlib.h>
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

void do_move(move_t move, bool *occupied) {
  assert(occupied[move.from]);
  assert(!occupied[move.to]);
  assert(occupied[move.removed]);
  occupied[move.to] = true;
  occupied[move.from] = false;
  occupied[move.removed] = false;
}

void undo_move(move_t move, bool *occupied) {
  assert(!occupied[move.from]);
  assert(occupied[move.to]);
  assert(!occupied[move.removed]);
  occupied[move.to] = false;
  occupied[move.from] = true;
  occupied[move.removed] = false;
}

struct state_impl *demand_index(struct state_impl *state_impl, unsigned index) {
  assert(index <= state_impl->frames_size);
  if (index == state_impl->frames_size) {
    return state_impl;
  } else {
    struct state_impl *new_state_impl =
      malloc(sizeof(struct state_impl) + sizeof(bool) * state_impl->size);
    new_state_impl->num_refs = 1;
    new_state_impl->frames_size = index;
    new_state_impl->frames_capacity = state_impl->frames_capacity;
    new_state_impl->frames = malloc(sizeof(struct history_frame) * new_state_impl->frames_capacity);
    for (unsigned i = 0; i < index; i++) {
      new_state_impl->frames[i] = (struct history_frame){state_impl->frames[i].move, 1};
    }
    new_state_impl->size = state_impl->size;
    memcpy(new_state_impl->occupied, state_impl->occupied, sizeof(bool) * state_impl->size);
    for (unsigned i = state_impl->frames_size - 1; i >= index; i--) {
      undo_move(state_impl->frames[i].move, new_state_impl->occupied);
    }
    return new_state_impl;
  }
}

state_t init_state(unsigned edge_size) {
  unsigned size = edge_size * (edge_size - 1) / 2;
  struct state_impl *new_state_impl =
    malloc(sizeof(struct state_impl) + sizeof(bool) * size);
  new_state_impl->num_refs = 1;
  new_state_impl->frames_size = 0;
  new_state_impl->frames_capacity = INITIAL_FRAMES_CAPACITY;
  new_state_impl->frames = malloc(sizeof(struct history_frame) * INITIAL_FRAMES_CAPACITY);
  new_state_impl->size = size;
  new_state_impl->occupied[0] = false;
  for (unsigned i = 1; i < size; i++) {
    new_state_impl->occupied[i] = true;
  }
  return (state_t){0, new_state_impl};
}

void delete_state(state_t state) {
  assert(state.index <= state.impl->frames_size);
  if (state.index == state.impl->frames_size) {
    state.impl->num_refs--;
    while (state.impl->num_refs == 0) {
      if (state.impl->frames_size > 0) {
        struct history_frame frame = state.impl->frames[--state.impl->frames_size];
        undo_move(frame.move, state.impl->occupied);
        state.impl->num_refs = frame.num_refs - 1;
      } else {
        free(state.impl->frames);
        free(state.impl);
        break;
      }
    }
  } else {
    state.impl->frames[state.index].num_refs--;
  }
}

void print_state(state_t state) {
  
}

_Bool is_solved(state_t state) {
  return state.index == state.impl->size - 2; // Each move removes one peg
}

state_t make_move(move_t move, state_t state) {
  struct state_impl *new_state_impl = demand_index(state.impl, state.index);
  assert(new_state_impl->frames_capacity >= new_state_impl->frames_size);
  if (new_state_impl->frames_capacity == new_state_impl->frames_size) {
    new_state_impl->frames_capacity *= 2;
    new_state_impl->frames =
      realloc(new_state_impl->frames, sizeof(struct history_frame) * new_state_impl->frames_capacity);
  }
  unsigned new_index = ++new_state_impl->frames_size;
  new_state_impl->frames[state.index] = (struct history_frame){move, new_state_impl->num_refs};
  new_state_impl->num_refs = 1;
  do_move(move, new_state_impl->occupied);
  return (state_t){new_index, new_state_impl};
}

union rows {
  struct row {signed num, start, end;} arr[5];
  struct {
    struct row prev_2;
    struct row prev_1;
    struct row curr;
    struct row next_1;
    struct row next_2;
  };
};
search move_t possible_move(unsigned from) {
  unsigned row_num = floor((sqrt(1 + 8 * from) - 1) / 2);
  union rows rows;
  for (unsigned i = 0; i < 5; i++) {
    rows.arr[i].num = row_num + i - 2;
    rows.arr[i].start = rows.arr[i].num * (rows.arr[i].num + 1) / 2;
    rows.arr[i].end = rows.arr[i].start + rows.arr[i].num - 1;
  }
  unsigned col_num = from - rows.curr.start;
  
  choice {
    {
      require rows.prev_2.start > 0;
      signed to = rows.prev_2.start + col_num - 2;
      require to >= rows.curr.start;
      signed removed = rows.prev_1.start + col_num - 1;
      succeed ((move_t){from, to, removed});
    }
    {
      require rows.prev_2.start > 0;
      signed to = rows.prev_2.start + col_num;
      require to <= rows.curr.end;
      signed removed = rows.prev_1.start + col_num;
      succeed ((move_t){from, to, removed});
    }
    {
      signed to = from - 2;
      require to >= rows.curr.start;
      signed removed = from - 1;
      succeed ((move_t){from, to, removed});
    }
    {
      unsigned to = from + 2;
      require to <= rows.curr.end;
      unsigned removed = from + 1;
      succeed ((move_t){from, to, removed});
    }
    {
      unsigned to = rows.next_2.start + col_num;
      unsigned removed = rows.next_1.start + col_num;
      succeed ((move_t){from, to, removed});
    }
    {
      unsigned to = rows.next_2.start + col_num + 2;
      unsigned removed = rows.next_1.start + col_num + 1;
      succeed ((move_t){from, to, removed});
    }
  }
}

search move_t valid_move(state_t state) {
  choice for (unsigned from = 0; from < state.impl->size; from++) {
    require state.impl->occupied[from];
    choose move_t move = possible_move(from);
    require move.to < state.impl->size;
    require !state.impl->occupied[move.to];
    require state.impl->occupied[move.removed];
    succeed move;
  }
}

void finalize_state(void *p) {
  delete_state(*(state_t *)p);
}

search solution_t solve(state_t state) {
  if (is_solved(state)) {
    delete_state(state);
    size_t num_moves = state.index;
    succeed ((solution_t){num_moves, malloc(sizeof(move_t) * num_moves)});
  } else {
    refcount_tag_t rt_state;
    struct state *p_state = refcount_final_malloc(sizeof(state_t), &rt_state, 0, NULL, finalize_state);
    *p_state = state;
    
    choose move_t move = valid_move(state)
      finally { remove_ref(rt_state); }
    rt_state;
    state_t new_state = make_move(move, state);
    
    choose solution_t solution = solve(new_state);
    solution.moves[state.index] = move;
    succeed solution;
  }
}

int main() {}
