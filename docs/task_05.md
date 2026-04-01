# Task 05: Adjust wage grid and convergence tolerance to obtain interior reservation wages

| Field | Value |
|-------|-------|
| **Task ID** | task_05 |
| **Title** | Adjust `w_min` and `tol_outer` to ensure interior reservation wages |
| **Date opened** | 2026-03-30 |
| **GitHub issue** | 6 |
| **Status** | in-progress |
| **Assignee** | executor agent |

## Motivation

Some reservation wages are hitting the wage-grid endpoints (accept_all or reject_all). This task adjusts the wage grid lower bound and tightens outer-loop tolerance to ensure reservation wages are interior solutions without destabilizing the solver.

## Specific Goal

- Modify parameters to test whether lowering `par.w_min` produces interior reservation wages.
- Then tighten `par.tol_outer` and find a compromise value that yields accurate results while maintaining solver stability.
- Record experiments, chosen parameter values, and reasoning; produce a short results table and recommended final parameter settings to commit.

## Success Criteria

- For a representative sample of asset states (singles and couples), the reservation wage solver returns bracket_found = true and flag = 'converged' (i.e., w_min < wR < w_max) for >= 95% of tested states.
- Residuals from `find_reservation_wage` are <= 1e-6 for converged cases.
- Outer loop converges within `par.max_outer` for the full grid and no NaNs or divergence warnings occur.
- The chosen `par.tol_outer` reduces outer-loop residuals meaningfully compared to baseline (par.tol_outer = 5e-1) without causing solver instability or excessive runtime (prefer runtime increase <= 2x).

## Inputs / Relevant Files

| File | Role |
|------|------|
| Code/model/set_parameters.m | Parameter definitions (`par.w_min`, `par.tol_outer`, etc.) |
| Code/model/find_reservation_wage.m | Reservation-wage root-finding routine and status flags |
| Code/model/compute_reservation_wages.m | Wrapper that computes reservation wages over grids |
| Code/model/solve_singles.m | Single-agent solver (for test runs) |
| docs/solution_tasks.md | Reference on reservation-wage logic and success checks |

## Scope Boundaries

- DO: Change parameter values in `Code/model/set_parameters.m`, run the model (singles/couples as needed), and record results.
- DO: Propose a final `par.w_min` and `par.tol_outer` (single agreed setting) and document why.
- DO NOT: Re-write solver algorithms, change grid construction logic, or refactor core routines beyond minimal, well-justified fixes.
- DO NOT: Merge any parameter changes to master without a reviewer sign-off.

## Proposed Experiment Plan

1. Baseline: record current outcomes with `par.w_min = 0.5`, `par.tol_outer = 5e-1`.
2. Experiment A — Lower wage floor:
   - Set `par.w_min = 0.2` and run the reservation-wage computations.
   - If corner solutions persist, try `par.w_min = 0.1`.
   - Record fraction of states with `accept_all` / `reject_all`.
3. Experiment B — Tighten outer tolerance:
   - With an interior `w_min` chosen from Experiment A, try `par.tol_outer` in {1e-1, 1e-2, 1e-3}.
   - For each value record: outer-loop residual, number of outer iterations, total runtime, and any solver warnings.
4. Choose a midpoint `par.tol_outer` that balances accuracy and stability (candidate: 1e-2 if stable; otherwise 1e-1 or 1e-3 depending on behavior).
5. Document final recommended settings and rationale (include a short table of results).

## Action Log

| Date | Agent | Action | Summary |
|------|-------|--------|---------|
| 2026-03-30 | orchestrator | created | Task doc created; experiments planned (lower `w_min`, tune `tol_outer`). |
| 2026-03-30 | orchestrator | executor-launched | Launching executor agent on task_05. |

## Outcome

_To be filled after executor runs experiments._

## Next Recommended Step

- Executor: run Experiments A and B, update this doc with results, pick final `par.w_min` and `par.tol_outer` and, if needed, open follow-up tasks.

## Follow-up Tasks (if this grows complex)

- task_05a — Execute wage-floor experiments and summarize results.
- task_05b — Tune `par.tol_outer` and analyze stability trade-offs.
- task_05c — Update code and tests, then prepare a PR with chosen parameter defaults.
