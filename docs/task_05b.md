# Task 05b: Investigate solver divergence when par.tol_outer = 4e-1

| Field | Value |
|-------|-------|
| **Task ID** | task_05b |
| **Title** | Investigate solver divergence when `par.tol_outer` = 4e-1 |
| **Date opened** | 2026-03-31 |
| **GitHub issue** | n/a |
| **Status** | in-progress |
| **Assignee** | executor agent |

## Motivation

When `par.tol_outer` is set to `4e-1` I observe immediate divergence of results; at `5e-1` the solver is very unstable. We need a careful, small diagnostic step to find where the outer iteration is losing stability before attempting fixes.

## Specific Goal (single, bounded executor task)

Instrument the couples outer-iteration code to log iteration diagnostics, then run one focused diagnostic experiment with `par.tol_outer = 4e-1` on a reduced grid. Keep code changes minimal and strictly limited to non-invasive logging (no algorithmic fixes). Deliverables from the executor (one small bundle):

- A diagnostics folder: `Code/model/diagnostics/task_05b/` containing
  - `diagnostics_task_05b.mat` (or .csv) with arrays: `iter`, `err_UU`, `err_Wm`, `err_Wf`, `err_EE`, `err` and timestamps
  - if a NaN/Inf occurs, one or more `snapshot_iter_###.mat` files with the value/policy arrays saved at that iteration
  - `notes.txt` (<= 1 page) with a short narrative of what happened and the exact command(s) used to run the test

Important constraints for the executor:

- Do only logging and one diagnostic run. Do NOT try to change solver algorithms or apply fixes in this task.
- Keep edits minimal and easy to revert (prefer adding a small logging block inside `solve_couples.m` or a short wrapper script).

## Success Criteria

- [ ] `diagnostics_task_05b.mat` saved in `Code/model/diagnostics/task_05b/`
- [ ] `iter` and per-component `err_*` time series recorded (outer-iteration length at least 5)
- [ ] If NaN/Inf occurs, at least one `snapshot_iter_###.mat` saved showing state at failure
- [ ] `notes.txt` with clear steps to reproduce the run and one short paragraph of observations

## Inputs / Relevant Files

| File | Role |
|------|------|
| Code/model/set_parameters.m | numeric defaults (contains `par.tol_outer`) |
| Code/model/main_solve.m | master script that runs the full solve |
| Code/model/solve_couples.m | outer iteration loop — primary place to add logging |
| Code/model/solve_couple_* .m | inner solvers called from the outer loop (for context) |

## Scope Boundaries

- DO: Add logging (write to MAT/CSV), run a single diagnostic experiment with `par.tol_outer = 4e-1`, save outputs and short notes.
- DO NOT: Make algorithmic changes, refactor the solver, run the full experiment suite, or attempt automated fixes.

## Step-by-step instructions (practical, for inexperienced RAs)

1. Create a diagnostics folder:

```matlab
cd('/Users/sofiavaldivia/Documents/GitHub/Household_JobSearch/Code/model')
mkdir('diagnostics')
mkdir(fullfile('diagnostics','task_05b'))
```

2. Set the diagnostic tolerance. The simplest approach is to temporarily set `par.tol_outer` in `set_parameters.m` (remember to revert later), or override immediately after the call in `main_solve.m` by adding the line shown below.

3. Minimal logging to insert (copy into `solve_couples.m` just before the outer `for iter = 1:par.max_outer` loop):

```matlab
% --- diagnostics (task_05b) ---
diagn_dir = fullfile(fileparts(mfilename('fullpath')), 'diagnostics', 'task_05b');
if ~exist(diagn_dir, 'dir'), mkdir(diagn_dir); end
diags.iter = [];
diags.err_UU = [];
diags.err_Wm = [];
diags.err_Wf = [];
diags.err_EE = [];
% ----------------------------
```

4. Inside the loop, after `err` is computed, append the diagnostic values and save periodically (every 5 iters):

```matlab
diags.iter(end+1) = iter;
diags.err_UU(end+1) = err_UU;
diags.err_Wm(end+1) = err_Wm;
diags.err_Wf(end+1) = err_Wf;
diags.err_EE(end+1) = err_EE;
if mod(iter,5)==0 || any(isnan([err_UU,err_Wm,err_Wf,err_EE]))
    save(fullfile(diagn_dir,'diagnostics_task_05b.mat'),'diags');
end
% If NaN/Inf found, save a snapshot and stop
if any(isnan(UU(:))) || any(isinf(UU(:)))
    save(fullfile(diagn_dir,sprintf('snapshot_iter_%03d.mat',iter)), 'UU','Wm','Wf','EE','iter');
    return
end
```

5. Run the diagnostic:

```matlab
% Option A (quick): edit Code/model/set_parameters.m and set par.tol_outer = 4e-1, then run:
main_solve

% Option B (temporary override): edit Code/model/main_solve.m and add after par = set_parameters();
par.tol_outer = 4e-1;  % temporary override for this diagnostic run
main_solve
```

6. When finished, collect files in `Code/model/diagnostics/task_05b/` and write `notes.txt` describing:

- Exact file edits made (copy-paste the small snippets added)
- The `par` values used (especially `par.tol_outer`, `par.damp`, `par.max_outer`, `par.max_iter`)
- A one-paragraph description of how `err` evolved and whether/when NaNs/Infs or spikes appeared

## Action Log

| Date | Agent | Action | Summary |
|------|-------|--------|---------|
| 2026-03-31 | orchestrator | created | Task doc created describing bounded diagnostic subtask; executor will add minimal logging and run a single test. |
| 2026-03-31 | orchestrator | status → in-progress | Launching executor agent. Note: par.tol_outer is already 4e-1 in set_parameters.m, no override needed. |

## Planned follow-up tasks (create separate task files after this diagnostic)

- Task 05c — Instrument inner solvers (`solve_couple_Wm`, `solve_couple_Wf`, `solve_couple_EE`) to record inner-iteration residuals and max iterations.
- Task 05d — Grid sensitivity: run small/medium/large grids to check whether coarseness causes instability.
- Task 05e — Tolerance sweep: systematic runs over `par.tol_outer` and `par.tol_hjb` to map stability boundary.
- Task 05f — Initial guess and damping tests: try stronger damping (`par.damp`) and alternative starting guesses.

## Outcome

_To be filled after the executor runs the diagnostic and the reviewer checks the outputs._

## Next Recommended Step

Executor: run the bounded diagnostic described above and attach the `diagnostics_task_05b.mat` and `notes.txt` to the task. Reviewer: verify the files exist, the logged arrays are sensible, and accept or request another small diagnostic.
