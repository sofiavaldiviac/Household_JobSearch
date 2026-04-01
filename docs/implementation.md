# Plan: MATLAB Solver for Couples Reservation Wages

## Context
We need to numerically solve the household job search model (from `model3.tex`) to obtain reservation wages for couples under different property regimes. This is the coding step following Tasks 1-2 in the solution roadmap. The solver uses finite differences following Achdou et al. (2022).

## Scope
- Full 3 asset dimensions: `a^J` (joint), `a_m`, `a_f` (individual)
- On-the-job search included (`s_i > 0`)
- Singles solved first (for divorce values), then couples
- Both property regimes: `theta = O` (universal) and `theta = L` (limited)
- Marriage rate set to 0 for first pass (avoids outer distribution loop)
- Wealth shocks set to 0 for first pass (add later)

## File Structure

All files in `/Users/sofiavaldivia/Documents/GitHub/Household_JobSearch/Code/`:

```
main_solve.m                  % Master script: parameters, calls solvers, plots
set_parameters.m              % Returns parameter struct
setup_grids.m                 % Asset/wage grids, quadrature weights
build_A_1d.m                  % Sparse 1D upwind drift matrix (singles)
build_A_3d.m                  % Sparse 3D upwind drift matrix (couples)
solve_singles.m               % Outer loop: iterate U_sin / E_sin to convergence
solve_single_hjb.m            % Inner HJB iteration for one gender's singles
compute_divorce_values.m      % Map singles values → divorce values on 3D grid
solve_couples.m               % Outer loop: iterate UU / Wm / Wf / EE
solve_couple_UU.m             % HJB for U(a^J, a_m, a_f)
solve_couple_Wm.m             % HJB for W_m(w_m, a^J, a_m, a_f)
solve_couple_Wf.m             % HJB for W_f(w_f, a^J, a_m, a_f)
solve_couple_EE.m             % HJB for E(w_m, w_f, a^J, a_m, a_f)
compute_reservation_wages.m   % Root-finding on converged value functions
plot_results.m                % Figures
```

## Grid Sizes

| Grid | Points | Range | Notes |
|------|--------|-------|-------|
| `a_sin` (singles) | 100 | [-1, 30] | Power-spaced (denser near constraint) |
| `a^J` (joint) | 50 | [-1, 30] | Power-spaced |
| `a_m` (male indiv.) | 15 | [0, 15] | |
| `a_f` (female indiv.) | 15 | [0, 15] | |
| `w` (wages) | 15 | [0.5, 3.0] | Log-normal distribution |

Problem sizes per sparse solve:
- Singles: 100 unknowns (trivial)
- Couple UU: 50 x 15 x 15 = 11,250 unknowns
- Couple Wm/Wf: 15 wage points x 11,250 = 15 solves each
- Couple EE: 15 x 15 wage pairs x 11,250 = 225 solves

**Estimated runtime: ~3-4 minutes.**

## Algorithm

### Step 1: Singles (solve first, independent of couples)
1. Initialize `U_i^sin(a)` and `E_i^sin(w,a)` from flow values
2. Outer loop: alternate solving `E_sin` (holding `U_sin` fixed) and `U_sin` (holding `E_sin` fixed) until convergence
3. Inner HJB: implicit finite differences with upwind scheme
   - `(1/Δt + ρ)I - A) V^{n+1} = u(c^n) + option_values^n + (1/Δt)V^n`

### Step 2: Divorce values
- For each `(a^J_i, a_m_j, a_f_k)` on couples grid, compute post-divorce assets:
  - `theta=O`: `a^D = (1-τ)/2 * (a^J + a_m + a_f)`, interpolate `U_sin(a^D)`
  - `theta=L`: `a_m^D = a^J/2 + a_m`, `a_f^D = a^J/2 + a_f`, interpolate separately

### Step 3: Couples (joint iteration)
1. Initialize all value functions from flow values
2. Outer loop:
   - Solve UU (using current Wm, Wf)
   - Solve Wm for each `w_m` (using current U, E, Wf)
   - Solve Wf for each `w_f` (using current U, E, Wm)
   - Solve EE for each `(w_m, w_f)` (using current Wm, Wf)
   - Check convergence across all value functions
3. Each inner solve: 3D implicit system with upwind on `a^J` (consumption choice) and forward differencing on `a_m, a_f` (deterministic drift `r*a_i ≥ 0`)

### Step 4: Reservation wages
- At each `(a^J, a_m, a_f)`: find `w^R_m` where `W_m(w^R_m, ...) = U(...)` via interpolation/bisection on the wage grid
- Compare across `theta = O` vs `theta = L`

## Key Numerical Details
- **Upwind for `a^J`**: forward diff when saving, backward when dissaving, steady-state at kinks
- **`a_m, a_f` always forward-differenced**: drift `r*a_i ≥ 0`
- **Sparse matrix**: 7 nonzeros per row max (self + 6 neighbors in 3D)
- **Large implicit step** `Δt = 1000`: near-Newton convergence, ~50 iterations
- **Damping**: `V^new = 0.5*V^computed + 0.5*V^old` if outer loop oscillates

## Implementation Order
1. `set_parameters.m`, `setup_grids.m` — foundations
2. `build_A_1d.m` — 1D upwind matrix (reusable pattern)
3. `solve_single_hjb.m`, `solve_singles.m` — singles problem end-to-end
4. `compute_divorce_values.m` — bridge singles → couples
5. `build_A_3d.m` — 3D upwind matrix (core numerical engine)
6. `solve_couple_UU.m` — first couples solver (establishes pattern)
7. `solve_couple_Wm.m`, `solve_couple_Wf.m` — worker-searcher
8. `solve_couple_EE.m` — dual-employed (most expensive)
9. `solve_couples.m` — outer iteration wrapper
10. `compute_reservation_wages.m`, `plot_results.m` — output
11. `main_solve.m` — master script tying everything together

## Verification
1. Run `main_solve.m` end-to-end, check convergence messages
2. Singles reservation wages should be decreasing in assets (wealthier agents are pickier)
3. Couples reservation wages under `theta=O` vs `theta=L` should differ: universal community property provides more insurance, so reservation wages should be higher (more selective job search)
4. Value functions should be increasing and concave in assets
5. Consumption should be smooth and increasing in assets
