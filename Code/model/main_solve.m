%% MAIN_SOLVE  Master script: solve household job search model.
%
%  Solves for reservation wages under two property regimes:
%    theta = 'O'  (universal community property)
%    theta = 'L'  (limited community property)
%
%  Following the model in model3.tex and the numerical method of
%  Achdou et al. (2022).

clear; clc; close all;
fprintf('============================================\n');
fprintf('  Household Job Search Model Solver\n');
fprintf('============================================\n\n');

cd '/Users/sofiavaldivia/Documents/GitHub/Household_JobSearch/Code/model'

tic;

%% ===== Step 0: Parameters and grids =====
par = set_parameters();
gr  = setup_grids(par);
fprintf('Grid sizes: N_aJ=%d, N_am=%d, N_af=%d, N_w=%d\n', ...
    gr.N_aJ, gr.N_am, gr.N_af, gr.N_w);
fprintf('3D couple grid: %d points\n', gr.N3);
fprintf('Singles grid: %d points\n\n', gr.N_a_sin);

%% ===== Step 1: Solve singles =====
[sol_m, sol_f] = solve_singles(par, gr);

% Quick sanity check: reservation wages should increase in assets
dw_m = diff(sol_m.wR_sin);
dw_f = diff(sol_f.wR_sin);
fprintf('Singles checks:\n');
fprintf('  Male  wR monotone decreasing: %s (%.0f%% of diffs < 0)\n', ...
    iff(all(dw_m <= 1e-10), 'YES', 'NO'), 100*mean(dw_m <= 1e-10));
fprintf('  Female wR monotone decreasing: %s (%.0f%% of diffs < 0)\n', ...
    iff(all(dw_f <= 1e-10), 'YES', 'NO'), 100*mean(dw_f <= 1e-10));
fprintf('  Male  wR range: [%.4f, %.4f]\n', min(sol_m.wR_sin), max(sol_m.wR_sin));
fprintf('  Female wR range: [%.4f, %.4f]\n\n', min(sol_f.wR_sin), max(sol_f.wR_sin));

%% ===== Step 2: Solve couples under theta = O (universal) =====
sol_O = solve_couples(sol_m, sol_f, 'O', par, gr);

%% ===== Step 3: Solve couples under theta = L (limited) =====
sol_L = solve_couples(sol_m, sol_f, 'L', par, gr);

%% ===== Step 4: Compute reservation wages =====
fprintf('Computing couple reservation wages...\n');
res_O = compute_reservation_wages(sol_O, par, gr);
res_L = compute_reservation_wages(sol_L, par, gr);

% Summary statistics
fprintf('\nReservation wage summary (median over grid):\n');
fprintf('  theta=O: male wR median = %.4f, female wR median = %.4f\n', ...
    median(res_O.wR_m(:)), median(res_O.wR_f(:)));
fprintf('  theta=L: male wR median = %.4f, female wR median = %.4f\n', ...
    median(res_L.wR_m(:)), median(res_L.wR_f(:)));
fprintf('  Diff (O-L): male = %.4f, female = %.4f\n', ...
    median(res_O.wR_m(:)) - median(res_L.wR_m(:)), ...
    median(res_O.wR_f(:)) - median(res_L.wR_f(:)));

elapsed = toc;
fprintf('\nTotal runtime: %.1f seconds (%.1f minutes)\n\n', elapsed, elapsed/60);

%% ===== Step 5: Plot results =====
plot_results(res_O, res_L, sol_m, sol_f, sol_O, sol_L, par, gr);

%% ===== Save results =====
save('results.mat', 'par', 'gr', 'sol_m', 'sol_f', 'sol_O', 'sol_L', 'res_O', 'res_L');
fprintf('Results saved to results.mat\n');
