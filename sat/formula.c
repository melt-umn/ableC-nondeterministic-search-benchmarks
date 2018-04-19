#include <formula.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>

literal_t literal(bool negated, var_t var) {
  return (literal_t){negated, var};
}

clause_t clause(size_t size, ...) {
  literal_t *literals = malloc(size * sizeof(literal_t));
  
  va_list args;
  va_start(args, size);
  for (size_t i = 0; i < size; i++) {
    literals[i] = va_arg(args, literal_t);
  }
  va_end(args);

  return (clause_t){size, literals};
}

formula_t formula(size_t num_vars, size_t size, ...) {
  clause_t *clauses = malloc(size * sizeof(clause_t));
  
  va_list args;
  va_start(args, size);
  for (size_t i = 0; i < size; i++) {
    clauses[i] = va_arg(args, clause_t);
  }
  va_end(args);

  return (formula_t){num_vars, size, clauses};
}

void print_formula(formula_t formula) {
  for (size_t i = 0; i < formula.size; i++) {
    clause_t clause = formula.clauses[i];
    if (i >= 1) {
      printf(" & ");
    }
    printf("(");
    for (size_t j = 0; j < clause.size; j++) {
      literal_t literal = clause.literals[j];
      if (j >= 1) {
        printf(" | ");
      }
      if (literal.negated) {
        printf("~");
      }
      printf("a%u", literal.var);
    }
    printf(")");
  }
  printf("\n");
}

void delete_formula(formula_t formula) {
  for (size_t i = 0; i < formula.size; i++) {
    free(formula.clauses[i].literals);
  }
  free(formula.clauses);
}
