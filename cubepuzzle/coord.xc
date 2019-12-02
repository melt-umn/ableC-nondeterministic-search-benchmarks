#include <search.xh>
#include <vector.xh>
#include <coord.xh>
#include <stdlib.h>
#include <gc.h>

vector<vector<coord_t>> apply(transform_t t, vector<coord_t> c) {
  vector<vector<coord_t>> result = vec<vector<coord_t>>[];
  match (t) {
    Direct(fn) -> {
      vector<coord_t> res_c = vec<coord_t>[];
      for (size_t i = 0; i < c.size; i++) {
        res_c.append(fn(c[i]));
      }
      result.append(res_c);
    }
    Seq(ts) -> {
      result.append(c);
      for (size_t i = 0; i < ts.size; i++) {
        vector<vector<coord_t>> new_result = vec<vector<coord_t>>[];
        for (size_t j = 0; j < result.size; j++) {
          new_result.extend(apply(ts[i], result[j]));
        }
        result = new_result;
      }
    }
    Choice(ts) -> {
      for (size_t i = 0; i < ts.size; i++) {
        result.extend(apply(ts[i], c));
      }
    }
  }
  return result;
}

transform_t id(void) {
  return Direct(gc::lambda (coord_t c) -> c);
}

transform_t shift(int8_t x, int8_t y, int8_t z) {
  return Direct(gc::lambda (coord_t c) -> (coord_t){c.x + x, c.y + y, c.z + z});
}

transform_t rotate_x(uint8_t n) {
  switch (n % 4) {
  case 0:
    return Direct(gc::lambda (coord_t c) -> (coord_t){c.x, c.y, c.z});
  case 1:
    return Direct(gc::lambda (coord_t c) -> (coord_t){c.x, c.z, -c.y});
  case 2:
    return Direct(gc::lambda (coord_t c) -> (coord_t){c.x, -c.y, -c.z});
  case 3:
    return Direct(gc::lambda (coord_t c) -> (coord_t){c.x, -c.z, c.y});
  }
}

transform_t rotate_y(uint8_t n) {
  switch (n % 4) {
  case 0:
    return Direct(gc::lambda (coord_t c) -> (coord_t){c.x, c.y, c.z});
  case 1:
    return Direct(gc::lambda (coord_t c) -> (coord_t){c.z, c.y, -c.x});
  case 2:
    return Direct(gc::lambda (coord_t c) -> (coord_t){-c.x, c.y, -c.z});
  case 3:
    return Direct(gc::lambda (coord_t c) -> (coord_t){-c.z, c.y, c.x});
  }
}

transform_t rotate_z(uint8_t n) {
  switch (n % 4) {
  case 0:
    return Direct(gc::lambda (coord_t c) -> (coord_t){c.x, c.y, c.z});
  case 1:
    return Direct(gc::lambda (coord_t c) -> (coord_t){c.y, -c.x, c.z});
  case 2:
    return Direct(gc::lambda (coord_t c) -> (coord_t){-c.x, -c.y, c.z});
  case 3:
    return Direct(gc::lambda (coord_t c) -> (coord_t){-c.y, c.x, c.z});
  }
}
