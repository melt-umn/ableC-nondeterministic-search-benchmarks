#include <formula.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>

#define INITIAL_LITERALS_CAPACITY 10

void sort_literals(size_t start, size_t end, literal_t *literals) {
  if (start < end) {
    // Partition
    literal_t pivot = literals[start];
    size_t i = start, j = end;
    while (1) {
      do i++; while (i < end && literals[i].var <= pivot.var);
      do j--; while (literals[j].var > pivot.var);
      if (i >= j) {
        break;
      }
      literal_t tmp = literals[i];
      literals[i] = literals[j];
      literals[j] = tmp;
    }
    // Pivot goes in the middle
    literals[start] = literals[j];
    literals[j] = pivot;
    
    // Sort halves recursively
    sort_literals(start, j, literals);
    sort_literals(j + 1, end, literals);
  }
}

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

  sort_literals(0, size, literals);

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

formula_t load_formula(const char *filename) {
  size_t linenum = 0;
  int c;
  FILE *file = fopen(filename, "r");

  // Try to open the file
  if (file == NULL) {
    fprintf(stderr, "Error opening file %s\n", filename);
    exit(1);
  }

  // Read initial comments
  c = getc(file);
  while (c == 'c') {
    do {
      c = getc(file);
      if (c == EOF) {
        goto failure;
      }
    } while (c != '\n');
    linenum++;
    c = getc(file);
  }
  if (c == EOF) {
    goto failure;
  } else {
    ungetc(c, file);
  }
  
  // Read the problem line
  size_t num_vars, size;
  if (fscanf(file, "p%*[ ]cnf%*[ ]%lu%*[ ]%lu%*[ \n]", &num_vars, &size) != 2) {
    goto failure;
  }
  
  // Read clauses
  clause_t *clauses = malloc(size * sizeof(clause_t));
  size_t current_clause = 0;
  size_t current_literals_size = 0, current_literals_capacity = INITIAL_LITERALS_CAPACITY;
  literal_t *current_literals = malloc(INITIAL_LITERALS_CAPACITY * sizeof(literal_t));
  
  int val;
  int status;
  while ((status = fscanf(file, "%d", &val)) != EOF) {
    if (status == 0) {
      goto failure;
    }
    
    // Handle delimiting whitespace
    do {
      c = getc(file);
      if (c == '\n') {
        linenum++;
      }
    } while (c == ' ' || c == '\n');
    if (c == '%' || c == EOF) {
      goto done;
    } else {
      ungetc(c, file);
    }
    
    if (val == 0) {
      // This clause is complete
      sort_literals(0, current_literals_size, current_literals);
      clauses[current_clause] = (clause_t){current_literals_size, current_literals};
      current_clause++;
      current_literals_size = 0;
      current_literals_capacity = INITIAL_LITERALS_CAPACITY;
      current_literals = malloc(INITIAL_LITERALS_CAPACITY * sizeof(literal_t));
    } else {
      // Add the var to the current clause
      if (current_clause >= size) {
        goto failure;
      }
      if (current_literals_size == current_literals_capacity) {
        current_literals_capacity *= 2;
        current_literals = realloc(current_literals, current_literals_capacity * sizeof(literal_t));
      }
      current_literals[current_literals_size] = (literal_t){val < 0, abs(val) - 1};
      current_literals_size++;
    }
  }
  
 done:
  if (current_literals_size) {
    sort_literals(0, current_literals_size, current_literals);
    clauses[current_clause] = (clause_t){current_literals_size, current_literals};
    current_clause++;
  }
  if (current_clause == size) {
    fclose(file);
    return (formula_t){num_vars, size, clauses};
  }
  
 failure:
  fprintf(stderr, "Error parsing file %s on line %lu\n", filename, linenum);
  exit(1);
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
