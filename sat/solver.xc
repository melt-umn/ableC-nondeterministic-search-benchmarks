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
    // All clauses are satisfied, since none remain
    succeed malloc(formula.num_vars * sizeof(bool));
  } else if (num_assignments == formula.num_vars) {
    // We have assigned all vars, but there must still be some empty (unsatisfiable) clauses
    fail;
  } else {
    assert(num_assignments < formula.num_vars);
    
    choose bool val = maybe();
    var_t var = sorted_vars[num_assignments];
    refcount_tag_t rt_new_clauses;
    clause_t *new_clauses = refcount_malloc(formula.size * sizeof(clause_t), &rt_new_clauses);
    size_t num_new_clauses = 0;
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
    //printf("a%u <- %s\n", var, val? "true" : "false");
    //print_formula(new_formula);

    choose bool *result = solve_sorted(num_assignments + 1, sorted_vars, new_formula)
      finally { remove_ref(rt_new_clauses); }
    rt_new_clauses;
    result[var] = val;

    succeed result;
  }
}

template<t>
void qsort_by(size_t start, size_t end, t vals[], closure<(t, t) -> int> cmp) {
  if (start < end) {
    // Partition
    t pivot = vals[start];
    size_t i = start, j = end;
    while (1) {
      do i++; while (i < end && cmp(vals[i], pivot) <= 0);
      do j--; while (cmp(vals[j], pivot) > 0);
      if (i >= j) {
        break;
      }
      t tmp = vals[i];
      vals[i] = vals[j];
      vals[j] = tmp;
    }
    // Pivot goes in the middle
    vals[start] = vals[j];
    vals[j] = pivot;

    // Sort halves recursively
    inst qsort_by<t>(start, j, vals, cmp);
    inst qsort_by<t>(j + 1, end, vals, cmp);
  }
}

search bool *solve(formula_t formula) {
  int keys[formula.num_vars];
  memset(keys, 0, sizeof(keys));
  // Heuristic: Pick the literal first that occurs in the most clauses in the same quality
  for (size_t i = 0; i < formula.size; i++) {
    clause_t clause = formula.clauses[i];
    for (size_t j = 0; j < clause.size; j++) {
      literal_t literal = clause.literals[j];
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

  // Allocate memory
  refcount_tag_t rt_sorted_vars, rt_sorted_clauses, rt_sorted_literals[formula.size];
  var_t *sorted_vars = refcount_malloc(formula.num_vars * sizeof(var_t), &rt_sorted_vars);
  for (size_t i = 0; i < formula.size; i++) {
    refcount_malloc(formula.clauses[i].size * sizeof(literal_t), rt_sorted_literals + i);
  }
  clause_t *sorted_clauses =
    refcount_refs_malloc(formula.size * sizeof(clause_t), &rt_sorted_clauses, formula.size, rt_sorted_literals);

  // Initialize sorted formula
  for (size_t i = 0; i < formula.num_vars; i++) {
    sorted_vars[i] = i;
  }
  closure<(var_t, var_t) -> int> cmp_var = lambda (var_t var1, var_t var2) -> (int) {
    int key1 = keys[var1], key2 = keys[var2], diff = key1 - key2;
    if (diff) {
      return diff;
    } else {
      return var1 - var2;
    }
  };
  closure<(literal_t, literal_t) -> int> cmp_literal =
    lambda (literal_t literal1, literal_t literal2) -> (cmp_var(literal1.var, literal2.var));
  inst qsort_by<var_t>(0, formula.num_vars, sorted_vars, cmp_var);
  cmp_var.remove_ref();
  for (size_t i = 0; i < formula.size; i++) {
    clause_t clause = formula.clauses[i];
    sorted_clauses[i].size = clause.size;
    literal_t *sorted_literals = rt_sorted_literals[i]->data;
    memcpy(sorted_literals, clause.literals, clause.size * sizeof(literal_t));
    inst qsort_by<literal_t>(0, clause.size, sorted_literals, cmp_literal);
    sorted_clauses[i].literals = sorted_literals;
  }
  cmp_literal.remove_ref();
  formula_t sorted_formula = (formula_t){formula.num_vars, formula.size, sorted_clauses};
  //print_formula(sorted_formula);

  // Search for a solution
  choose bool *result = solve_sorted(0, sorted_vars, sorted_formula)
    finally {
    remove_ref(rt_sorted_vars);
    remove_ref(rt_sorted_clauses);
    for (size_t i = 0; i < formula.size; i++) {
      remove_ref(rt_sorted_literals[i]);
    }
  }
  rt_sorted_vars, rt_sorted_clauses;
  
  succeed result;
}
