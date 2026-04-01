# Task 04: Rewrite compute_reservation_wages to use find_reservation_wage

| Field | Value |
|-------|-------|
| **Task ID** | task_04 |
| **Title** | Rewrite compute_reservation_wages to use find_reservation_wage |
| **Date opened** | 2026-03-30 |
| **GitHub issue** | #4 |
| **Status** | accepted |
| **Assignee** | executor agent |

## Motivation

`compute_reservation_wages.m` uses a local `find_reservation` helper based on linear interpolation. The singles solver already uses `find_reservation_wage.m` which is more robust (bracket + bisection to tol=1e-10, with status flags). The couples code should use the same function for consistency and accuracy.

## Specific Goal

Rewrite `Code/model/compute_reservation_wages.m` to call `find_reservation_wage.m` at each 3D grid point, following the same pattern used in `solve_singles.m` (lines 104-105). Delete the local `find_reservation` helper. Keep the function signature and output struct unchanged so `main_solve.m` needs no changes.

## Success Criteria

- [ ] `compute_reservation_wages.m` calls `find_reservation_wage` (not a local helper)
- [ ] Local `find_reservation` helper function removed from the file
- [ ] Function signature and output struct (`res.wR_m`, `res.wR_f`) unchanged
- [ ] `main_solve.m` steps 1–4 run end-to-end without errors
- [ ] All reservation wages within wage grid bounds `[w_min, w_max]`
- [ ] No NaN or Inf in output

## Inputs / Relevant Files

| File | Role |
|------|------|
| `Code/model/compute_reservation_wages.m` | File to rewrite |
| `Code/model/find_reservation_wage.m` | Bisection function to call (already exists) |
| `Code/model/solve_singles.m` (lines 104-105) | Reference: the pattern to follow |
| `Code/model/main_solve.m` (lines 47-60) | Caller — should not need changes |

## Scope Boundaries

- DO: Rewrite the body of `compute_reservation_wages.m` to loop over (i,j,k) and call `find_reservation_wage` at each point.
- DO: Delete the local `find_reservation` helper.
- DO: Keep the function signature `res = compute_reservation_wages(sol, par, gr)` and output fields `res.wR_m`, `res.wR_f` unchanged.
- DO NOT: Modify `find_reservation_wage.m`, `main_solve.m`, or any solver files.
- DO NOT: Change the output struct fields or dimensions.

## Action Log

| Date | Agent | Action | Summary |
|------|-------|--------|---------|
| 2026-03-30 | orchestrator | created | Task doc created |
| 2026-03-30 | executor | implemented | Replaced `find_reservation` calls with `find_reservation_wage` on lines 27,30. Deleted local `find_reservation` helper (was lines 41-60). MATLAB end-to-end test passed: no errors, no NaN/Inf, all reservation wages at 0.5000 for both regimes. |

## Outcome

ACCEPTED. `compute_reservation_wages.m` now calls `find_reservation_wage` (bisection) at each 3D grid point. Local helper deleted. MATLAB end-to-end test passed (steps 1-4 of main_solve). All wR = 0.5000 (w_min) for both regimes — all offers accepted, consistent with b=0.4 < w_min=0.5 and loose convergence tolerance.

## Next Recommended Step

Investigate why couple reservation wages are all at the boundary (w_min). Likely causes: (1) loose convergence tolerance (tol=0.5) means value functions aren't accurate enough for interior wR; (2) parameter calibration (b too low relative to w_min). Consider tightening tolerance or adjusting parameters to get interior reservation wages that differentiate across regimes.
