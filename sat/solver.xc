#include <formula.h>
#include <solver.xh>
#include <search.xh>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include <assert.h>

search static inline bool maybe(bool preference) {
  choice {
    succeed preference;
    succeed !preference;
  }
}

search bool *solve_reduced(formula_t formula);

search bool *solve_copy(formula_t formula) {
  // Eliminate all singular clauses
  bool failed = false;
  size_t num_assignments = 0;
  refcount_tag_t rt_assignments;
  literal_t *assignments = refcount_malloc(formula.num_vars * sizeof(literal_t), &rt_assignments);
  refcount_tag_t rt_fresh_clause[formula.size];
  memset(rt_fresh_clause, 0, formula.size * sizeof(refcount_tag_t));
  while (1) {
    bool has_singular_clause = 0;
    literal_t singular_clause;
    for (size_t i = 0; i < formula.size; i++) {
      clause_t clause = formula.clauses[i];
      if (clause.size == 0) {
        failed = true;
        break;
      } else if (clause.size == 1) {
        has_singular_clause = true;
        singular_clause = clause.literals[0];
        break;
      }
    }
    
    if (!has_singular_clause || failed) {
      break;
    }
    
    assignments[num_assignments] = singular_clause;
    num_assignments++;
    
    size_t new_size = 0;
    for (size_t i = 0; i < formula.size; i++) {
      clause_t clause = formula.clauses[i];
      bool literal_removed = false;
      for (size_t j = 0; j < clause.size; j++) {
        literal_t literal = clause.literals[j];
        if (literal.var == singular_clause.var) {
          // Var is being assigned
          if (literal.negated == singular_clause.negated) {
            // Quality of var matches singular clause, remove the clause
            goto next_clause; // Continue outer loop
          } else {
            // Quality of var doesn't match singular clause, remove the var
            literal_removed = true;
          }
        } else if (literal.var > singular_clause.var) {
          // Vars are in sorted order
          break;
        }
      }
      
      if (literal_removed) {
        // If a var is to be removed, copy the clause excluding those literals
        if (rt_fresh_clause[new_size] != NULL) {
          remove_ref(rt_fresh_clause[new_size]);
        }
        literal_t *literals =
          refcount_malloc(clause.size * sizeof(literal_t), rt_fresh_clause + new_size);
        size_t size = 0;
        for (size_t j = 0; j < clause.size; j++) {
          literal_t literal = clause.literals[j];
          if (literal.var != singular_clause.var) {
            literals[size] = literal;
            size++;
          }
        }
        clause = (clause_t){size, literals};
      } else {
        if (rt_fresh_clause[i] != NULL) {
          add_ref(rt_fresh_clause[i]);
        }
        if (rt_fresh_clause[new_size] != NULL) {
          remove_ref(rt_fresh_clause[new_size]);
        }
        rt_fresh_clause[new_size] = rt_fresh_clause[i];
      }
      
      formula.clauses[new_size] = clause;
      new_size++;
      
    next_clause:;
    }
    for (size_t i = new_size; i < formula.size; i++) {
      if (rt_fresh_clause[i] != NULL) {
        remove_ref(rt_fresh_clause[i]);
      }
    }
    
    formula.size = new_size;
    //print_formula(formula);
  }
  
  require !failed;

  size_t num_fresh_clauses = 0;
  for (size_t i = 0; i < formula.size; i++) {
    if (rt_fresh_clause[i] != NULL) {
      rt_fresh_clause[num_fresh_clauses] = rt_fresh_clause[i];
      num_fresh_clauses++;
    }
  }
  refcount_tag_t rt_fresh_clauses = refcount_wrap(1, num_fresh_clauses, rt_fresh_clause);
  
  choose bool *result = solve_reduced(formula)
    finally { remove_ref(rt_assignments); remove_ref(rt_fresh_clauses); }
  
  rt_assignments, rt_fresh_clauses;
  
  for (size_t i = 0; i < num_assignments; i++) {
    literal_t singular_clause = assignments[i];
    result[singular_clause.var] = !singular_clause.negated;
  }
  succeed result;
}

// Solve a formula that contains no singular or empty clauses
search bool *solve_reduced(formula_t formula) {
  if (formula.size == 0) {
    // All clauses are satisfied, since the formula has no clauses
    succeed malloc(formula.num_vars * sizeof(bool));
  } else {
    // Heuristic: Pick the var that occurs with the same quality in the most clauses
    bool exists[formula.num_vars];
    memset(exists, 0, formula.num_vars * sizeof(bool));
    int weights[formula.num_vars];
    memset(weights, 0, formula.num_vars * sizeof(int));
    for (size_t i = 0; i < formula.size; i++) {
      clause_t clause = formula.clauses[i];
      for (size_t j = 0; j < clause.size; j++) {
        literal_t literal = clause.literals[j];
        exists[literal.var] = true;
        if (literal.negated) {
          weights[literal.var]--;
        } else {
          weights[literal.var]++;
        }
      }
    }
    var_t var;
    int max_weight;
    bool found_var = false;
    for (size_t i = 0; i < formula.num_vars; i++) {
      int weight = weights[i];
      if (exists[i] && (!found_var || abs(weight) > abs(max_weight))) {
        var = i;
        max_weight = weight;
        found_var = true;
      }
    }
    
    // Nondeterministicly choose a value to assign by adding a singular clause
    // Prefer assignment of vars predominant quality
    choose bool val = maybe(max_weight > 0);
    size_t new_size = formula.size + 1;
    refcount_tag_t rt_new_clauses;
    clause_t *new_clauses = refcount_malloc(new_size * sizeof(clause_t), &rt_new_clauses);
    new_clauses[0] = clause(1, literal(!val, var));
    memcpy(new_clauses + 1, formula.clauses, formula.size * sizeof(clause_t));
    formula_t new_formula = (formula_t){formula.num_vars, new_size, new_clauses};
    //printf("a%u <- %s\n", var, val? "true" : "false");
    //print_formula(new_formula);
    
    // Recursively solve the resulting formula
    choose bool *result = solve_copy(new_formula)
      finally { remove_ref(rt_new_clauses); }
    rt_new_clauses;
    result[var] = val;
    
    succeed result;
  }
}

search bool *solve(formula_t formula) {
  refcount_tag_t rt_clauses;
  clause_t *clauses = refcount_malloc(formula.size * sizeof(clause_t), &rt_clauses);
  memcpy(clauses, formula.clauses, formula.size * sizeof(clause_t));
  choose bool *result = solve_copy((formula_t){formula.num_vars, formula.size, clauses})
    finally { remove_ref(rt_clauses); }
  rt_clauses;
  succeed result;
}
