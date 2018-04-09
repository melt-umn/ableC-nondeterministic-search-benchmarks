#include <solitare.xh>
#include <search.xh>
#include <refcount.h>
#include <stdlib.h>
#include <math.h>
#include <stdio.h>

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
search move_t potential_move(unsigned from) {
  unsigned row_num = floor((sqrt(1 + 8 * from) - 1) / 2);
  union rows rows;
  for (unsigned i = 0; i < 5; i++) {
    rows.arr[i].num = row_num + i - 2;
    rows.arr[i].start = rows.arr[i].num * (rows.arr[i].num + 1) / 2;
    rows.arr[i].end = rows.arr[i].start + rows.arr[i].num;
  }
  unsigned col_num = from - rows.curr.start;
  
  choice {
    {
      require rows.prev_2.start >= 0;
      signed to = rows.prev_2.start + col_num - 2;
      require to >= rows.prev_2.start;
      signed removed = rows.prev_1.start + col_num - 1;
      succeed ((move_t){from, to, removed});
    }
    {
      require rows.prev_2.start >= 0;
      signed to = rows.prev_2.start + col_num;
      require to <= rows.prev_2.end;
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
  choose signed from = range(0, get_size(state));
  require is_occupied(state, from);
  choose move_t move = potential_move(from);
  require move.to < get_size(state);
  require !is_occupied(state, move.to);
  require is_occupied(state, move.removed);
  succeed move;
}

void finalize_state(void *p) {
  delete_state(*(state_t *)p);
}

search solution_t solve_direct(state_t state) {
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
    //print_move(move);
    state_t new_state = make_move(move, state);
    //print_state(new_state);
    
    choose solution_t solution = solve_direct(new_state);
    solution.moves[state.index] = move;
    
    succeed solution;
  }
}

search solution_t solve(state_t state) {
  choose succeed solve_direct(copy_state(state));
}

void delete_solution(solution_t solution) {
  free(solution.moves);
}

void print_state(state_t state) {
  unsigned edge_size = get_edge_size(state);
  unsigned i = 0;
  for (unsigned row = 0; row < edge_size; row++) {
    for (unsigned j = 0; j < edge_size - row; j++) {
      printf("  ");
    }
    for (unsigned col = 0; col <= row; col++) {
      if (is_occupied(state, i)) {
        printf(" \e[1m%-3d\e[0m", i);
      } else {
        printf(" \e[2m%-3d\e[0m", i);
      }
      i++;
    }
    printf("\n");
  }
}

void print_move(move_t move) {
  printf("%d -> %d x %d\n", move.from, move.to, move.removed);
}

void print_solution(state_t state, solution_t solution) {
  print_state(state);
  for (size_t i = 0; i < solution.num_moves; i++) {
    printf("\n");
    print_move(solution.moves[i]);
    state_t new_state = make_move(solution.moves[i], state);
    if (i > 0) {
      delete_state(state);
    }
    state = new_state;
    print_state(state);
  }
  if (solution.num_moves > 0) {
    delete_state(state);
  }
}
