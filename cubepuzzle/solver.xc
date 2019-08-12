#include <solver.xh>
#include <search.xh>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <math.h>
#include <gc.h>
#include <assert.h>

void print_state(state_t state) {
  for (int z = 0; z < BOX_SIZE; z++) {
    for (int y = BOX_SIZE - 1; y >= 0; y--) {
      for (int x = 0; x < BOX_SIZE; x++) {
        printf("%c ", is_occupied(state, (coord_t){x, y, z})? '*' : '_');
      }
      printf("\n");
    }
    printf("\n");
  }
}

vector<state_t> get_moves(void) {
  transform_t t =
    Seq(vec[Choice(vec[id(), Seq(vec[rotate_x(2), shift(0, 1, 0)])]),
            Choice(vec[id(), shift(1, 0, 0)]),
            Choice(vec[id(), shift(0, 1, 0), shift(0, 2, 0), shift(0, 3, 0)]),
            Choice(vec[id(), shift(0, 0, 1), shift(0, 0, 2), shift(0, 0, 3), shift(0, 0, 4)]),
            Choice(vec[id(),
                       Seq(vec[shift(-2, -2, 0), rotate_z(1), shift(2, 2, 0)]),
                       Seq(vec[shift(-2, -2, 0), rotate_z(2), shift(2, 2, 0)]),
                       Seq(vec[shift(-2, -2, 0), rotate_z(3), shift(2, 2, 0)])]),
            Choice(vec[id(),
                       Seq(vec[shift(0, -2, -2), rotate_x(1), shift(0, 2, 2)]),
                       Seq(vec[shift(-2, 0, -2), rotate_y(1), shift(2, 0, 2)])])]);
  
  vector<coord_t> piece_coords =
    vec[(coord_t){0, 0, 0}, (coord_t){1, 0, 0}, (coord_t){2, 0, 0}, (coord_t){2, 1, 0}, (coord_t){3, 1, 0}];

  vector<vector<coord_t>> trans_coords = apply(t, piece_coords);
  
  vector<state_t> result = vec<state_t>[];
  for (size_t i = 0; i < trans_coords.size; i++) {
    state_t s = 0;
    for (size_t j = 0; j < piece_coords.size; j++) {
      coord_t c = trans_coords[i][j];
      assert(in_box(c));
      s |= occupied(c);
    }
    result.append(s);
  }
  return result;
}

search vector<state_t> solve_help(unsigned num_pieces, state_t state, uint8_t first_open, vector<state_t> moves) {
  if (num_pieces == 0) {
    succeed vec<state_t>[];
  } else {
    assert(first_open < BOX_VOLUME);
    choice for (unsigned i = 0; i < moves.size; i++) {
      state_t move = moves[i];
      require (move >> first_open) & 1;
      require !(move & state);
      state_t new_state = move | state;
      uint8_t next_open = first_open;
      while ((new_state >> next_open) & 1) {
        next_open++;
      }
      spawn;
      choose vector<state_t> solution =
        solve_help(num_pieces - 1, new_state, next_open, moves);
      solution.append(move);
      succeed solution;
    }
  }
}

search vector<state_t> solve(unsigned num_pieces) {
  choose succeed solve_help(num_pieces, 0, 0, get_moves());
}
