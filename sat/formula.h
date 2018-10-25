#include <stdlib.h>

#ifndef _FORMULA_XH
#define _FORMULA_XH

typedef unsigned var_t;

typedef struct literal {
  _Bool negated;
  var_t var;
} literal_t;

typedef struct clause {
  size_t size;
  literal_t *literals;
} clause_t;

typedef struct formula {
  size_t num_vars;
  size_t size;
  clause_t *clauses;
} formula_t;

literal_t literal(_Bool negated, var_t var);
clause_t clause(size_t size, ...);
formula_t formula(size_t num_vars, size_t size, ...);

formula_t load_formula(const char *filename);

void print_formula(formula_t formula);
void delete_formula(formula_t formula);

#endif
