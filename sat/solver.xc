#include <formula.h>
#include <solver.xh>
#include <search.xh>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <assert.h>

search static inline bool maybe(void) {
  choice {
    succeed true;
    succeed false;
  }
}

search bool *solve_sorted(size_t num_assignments, var_t *sorted_vars, formula_t formula) {
  if (formula.size == 0) {
    succeed malloc(formula.num_vars * sizeof(bool));
  } else {
    assert(num_assignments < formula.num_vars);
    
    choose bool val = maybe();
    refcount_tag_t rt_new_clauses;
    clause_t *new_clauses = refcount_malloc(formula.size * sizeof(clause_t), &rt_new_clauses);
    size_t num_new_clauses = 0;
    var_t var = sorted_vars[num_assignments];
    bool failed = false;
    for (size_t i = 0; i < formula.size; i++) {
      clause_t clause = formula.clauses[i];
      if (clause.size == 0) {
        // The clause is empty
        failed = true;
        break;
      } else {
        literal_t literal = clause.literals[0];
        if (literal.var == var) {
          // Clause contains the var
          if (literal.negated == val) {
            // Literal is false, keep the clause and remove the literal
            new_clauses[num_new_clauses] = (clause_t){clause.size - 1, clause.literals + 1};
            num_new_clauses++;
          }
        } else {
          // Clause doesn't contain the var, it is unaffected
          new_clauses[num_new_clauses] = clause;
          num_new_clauses++;
        }
      }
    }

    require !failed;
    formula_t new_formula = (formula_t){formula.num_vars, num_new_clauses, new_clauses};

    choose bool *result = solve_sorted(num_assignments + 1, sorted_vars, new_formula)
      finally { remove_ref(rt_new_clauses); }
    rt_new_clauses;
    result[var] = val;

    succeed result;
  }
}

template<t>
void qsort_by(size_t start, size_t end, t vals[], closure<(t) -> int> key) {
  if (start < end) {
    // Partition
    int pivot = key(vals[start]);
    size_t i = start, j = end + 1;
    while (i < j) {
      do i++; while (key(vals[i]) <= pivot && i <= end);
      do j--; while (key(vals[j]) > pivot);
      t tmp = vals[i];
      vals[i] = vals[j];
      vals[j] = tmp;
    }
    // Pivot goes in the middle
    t tmp = vals[start];
    vals[start] = vals[j];
    vals[j] = tmp;

    // Sort halves recursively
    inst qsort_by<t>(start, j - 1, vals, key);
    inst qsort_by<t>(j + 1, end, vals, key);
  }
}

search bool *solve(formula_t formula) {
  int keys[formula.num_vars];
  // Heuristic: Pick the literal first that occurs in the most clauses in the same quality
  for (size_t i = 0; i < formula.size; i++) {
    clause_t clause = formula.clauses[i];
    for (size_t j = 0; j < clause.size; j++) {
      literal_t literal = clause.literals[i];
      if (literal.negated) {
        keys[literal.var]--;
      } else {
        keys[literal.var]++;
      }
    }
  }
  for (size_t i = 0; i < formula.num_vars; i++) {
    keys[i] = formula.num_vars - abs(keys[i]);
  }

  refcount_tag_t rt_sorted_vars, rt_sorted_clauses;
  var_t *sorted_vars = refcount_malloc(formula.num_vars * sizeof(var_t), &rt_sorted_vars);
  clause_t *sorted_clauses = refcount_malloc(formula.num_vars * sizeof(clause_t), &rt_sorted_clauses);
  closure<(var_t) -> int> var_key = lambda (var_t var) -> (keys[var]);
  inst qsort_by<var_t>(0, formula.num_vars, sorted_vars, var_key);
  var_key.remove_ref();
  closure<(literal_t) -> int> literal_key = lambda (literal_t literal) -> (keys[literal.var]);
  for (size_t i = 0; i < formula.size; i++) {
    clause_t clause = sorted_clauses[i];
    sorted_clauses[i].size = clause.size;
    literal_t *sorted_literals = malloc(clause.size * sizeof(literal_t));
    memcpy(sorted_literals, clause.literals, clause.size * sizeof(literal_t));
    inst qsort_by<literal_t>(0, clause.size, sorted_literals, literal_key);
    sorted_clauses[i].literals = sorted_literals;
  }
  formula_t sorted_formula = (formula_t){formula.num_vars, formula.size, sorted_clauses};
  literal_key.remove_ref();

  choose bool *result = solve_sorted(0, sorted_vars, sorted_formula)
    finally { remove_ref(rt_sorted_vars); remove_ref(rt_sorted_clauses); }
  rt_sorted_vars, rt_sorted_clauses;
  succeed result;
}
