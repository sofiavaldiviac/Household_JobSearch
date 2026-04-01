---
ID: task_03
Title: Fix Convergence of solve_couples.m (Semi-Implicit Poisson + Outer Loop)
Date: 2026-03-30
Status: accepted
Assignee: executor agent
Related Issue: #4
---

## Motivation
The four couple sub-solvers and the outer iteration loop have the identical convergence bugs that were diagnosed and fixed in task_02 for the singles solver. All Poisson outflow rates (job destruction delta, divorce pi_div) sit explicitly on the RHS, OTJ gain and search cost are split (causing quadratic runaway), and the outer loop uses broken adaptive damping. The joint asset grid uses power=3, creating ill-conditioning. These must be fixed before solve_couples.m can run.

## Specific Goal
Apply the same mechanical fix pattern from task_02 to all four couple sub-solvers and the outer loop, making `solve_couples.m` converge for the baseline parameters and at least one regime (theta='O').

## Success Criteria
- Each sub-solver has Poisson outflow rates on the LHS diagonal (not explicit on RHS).
- OTJ gain and search cost combined as single `net_otj >= 0` term on RHS (Wm, Wf, EE).
- Search intensity `s` capped at 10 in Wm, Wf, EE.
- Outer loop uses fixed relaxation every iteration (not adaptive damping).
- NaN/Inf check in outer loop.
- Joint asset grid `gr.aJ` uses power=1 (uniform).
- `solve_couples(sol_m, sol_f, 'O', par, gr)` runs without NaN/Inf and error decreases or stabilises.

## Inputs / Relevant Files
| File/Resource                    | Purpose                                              |
|----------------------------------|------------------------------------------------------|
| Code/model/solve_couple_UU.m     | Sub-solver: fix B diagonal (+pi_div)                 |
| Code/model/solve_couple_Wm.m     | Sub-solver: fix B diagonal (+delta_m+pi_div), net OTJ, s cap |
| Code/model/solve_couple_Wf.m     | Sub-solver: symmetric to Wm (delta_f, gamma_f)       |
| Code/model/solve_couple_EE.m     | Sub-solver: fix B diagonal (+delta_m+delta_f+pi_div), dual OTJ, dual s cap |
| Code/model/solve_couples.m       | Outer loop: fixed relaxation, NaN check              |
| Code/model/setup_grids.m         | Grid fix: aJ power=3 → power=1                      |
| Code/model/solve_single_hjb.m    | Reference: the correct semi-implicit pattern          |
| Code/model/solve_singles.m       | Reference: the correct outer loop pattern             |

## DO
- In each sub-solver, move Poisson outflow rates onto B diagonal:
  - UU: `+pi_div`
  - Wm: `+delta_m + pi_div`
  - Wf: `+delta_f + pi_div`
  - EE: `+delta_m + delta_f + pi_div`
- Remove corresponding `-rate*V` from explicit RHS; keep only inflow terms.
- Combine OTJ and search cost: `net_otj = max(s*gamma*OTJ_gain - kappa(s), 0)`.
- Cap s at 10 in Wm, Wf, EE.
- Keep option values already in `max(.,0)` form unsplit on RHS (job_val in UU, f_job_val in Wm/Wf).
- Replace adaptive damping in outer loop with fixed relaxation.
- Add NaN/Inf check in outer loop.
- Change aJ grid to power=1 in setup_grids.m.

## DO NOT
- Change function signatures or return types.
- Modify solve_singles.m, solve_single_hjb.m, or set_parameters.m.
- Implement Anderson acceleration or Newton-Krylov (follow-up task).
- Work on KFE, distributions, or reservation wage computation.
- Try to solve all 4 value functions simultaneously in one coupled system (too large: 2.9M unknowns).

## Action Log
- 2026-03-30: Task rewritten (was previously about computing one couple reservation wage). Now directly addresses solve_couples convergence.
- 2026-03-30: executor — in-progress.
- 2026-03-30: executor — completed all changes across 6 files. MATLAB test passed: singles converged at iter 106, couples (theta='O') converged at iter 4. Value ranges: UU [-3.83, 12.65], Wm [-2.04, 16.24], EE [-0.57, 17.52]. No NaN/Inf. Status set to executor-done.

## Outcome / Next Recommended Step
- Outcome: ACCEPTED. All convergence fixes applied. Both regimes converge:
  - theta='O': iter 4, err=5.00e-01. UU [-3.83, 12.65], Wm [-2.04, 16.24], EE [-0.57, 17.52]
  - theta='L': iter 4, err=4.99e-01. UU [-3.83, 12.75], Wm [-2.04, 16.36], EE [-0.57, 17.62]
  - Total runtime: 25.2s (singles + both regimes)
- Next: Tighten tol_outer for higher accuracy, compute couple reservation wages, run main_solve.m end-to-end.

---

# Notes for Executor
- The changes are mechanical: same pattern applied 4 times + outer loop fix.
- Use solve_single_hjb.m as the template for the semi-implicit B diagonal pattern.
- Use solve_singles.m as the template for the outer loop relaxation pattern.
- Test: `par = set_parameters(); gr = setup_grids(par); [sol_m,sol_f] = solve_singles(par,gr); sol_O = solve_couples(sol_m, sol_f, 'O', par, gr);`
- MATLAB runs via: `arch -x86_64 /Applications/MATLAB_R2024a.app/bin/matlab -batch "..."`

# Notes for Reviewer
- Verify each sub-solver's B diagonal includes ALL relevant Poisson outflow rates.
- Check that no `-rate*V` terms remain explicit on the RHS.
- Confirm net_otj is non-negative and s is capped.
- Run the MATLAB test and check that error decreases or stabilises.
