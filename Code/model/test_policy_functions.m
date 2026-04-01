% TEST_POLICY_FUNCTIONS  Sanity-check script for policy functions.
%
%   Runs compute_c_policy, compute_s_policy, and find_reservation_wage
%   on converged value functions from solve_singles, and reports pass/fail
%   for each criterion.
%
%   Success criteria (from docs/task_01.md):
%     1. c* > 0 at all test grid points.
%     2. c* is monotonically increasing in assets at test points.
%     3. s* >= 0 at all test grid points.
%     4. wR falls within wage grid bounds with |W(wR) - U| < tol.
%     5. wR output includes a status flag (bracket_found).
%     6. No NaN or Inf in any output.

fprintf('============================================\n');
fprintf('  Policy Function Tests\n');
fprintf('============================================\n\n');

%% ===== Setup: load parameters, grids, solve singles =====
fprintf('Setting up parameters and grids...\n');
par = set_parameters();
gr  = setup_grids(par);

fprintf('Solving singles problem (this provides converged value functions)...\n');
[sol_m, sol_f] = solve_singles(par, gr);

N_a = gr.N_a_sin;
N_w = gr.N_w;

n_pass = 0;
n_fail = 0;
n_test = 0;

%% ===== Test 1: compute_c_policy =====
fprintf('\n--- Test 1: compute_c_policy ---\n');

% Compute Va from the converged unemployed value function using finite diffs
Va_U = zeros(N_a, 1);
Va_U(1:N_a-1) = diff(sol_m.U_sin) ./ gr.da_sin;
Va_U(N_a) = Va_U(N_a-1);  % extrapolate last point

% Also test on employed value function at median wage
iw_mid = ceil(N_w / 2);
Va_E = zeros(N_a, 1);
Va_E(1:N_a-1) = diff(sol_m.E_sin(iw_mid,:)') ./ gr.da_sin;
Va_E(N_a) = Va_E(N_a-1);

% Compute c*
c_star_U = compute_c_policy(Va_U, par);
c_star_E = compute_c_policy(Va_E, par);

% Test 1a: c* > 0 everywhere
n_test = n_test + 1;
if all(c_star_U > 0) && all(c_star_E > 0)
    fprintf('  [PASS] c* > 0 at all test grid points.\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] c* <= 0 found at some grid points.\n');
    n_fail = n_fail + 1;
end

% Test 1b: c* monotonically increasing in assets (unemployed)
n_test = n_test + 1;
dc_U = diff(c_star_U);
if all(dc_U >= -1e-10)
    fprintf('  [PASS] c* (unemployed) is monotonically increasing in assets.\n');
    n_pass = n_pass + 1;
else
    n_violations = sum(dc_U < -1e-10);
    fprintf('  [FAIL] c* (unemployed) is NOT monotone: %d violations.\n', n_violations);
    n_fail = n_fail + 1;
end

% Test 1c: c* monotonically increasing in assets (employed at median wage)
n_test = n_test + 1;
dc_E = diff(c_star_E);
if all(dc_E >= -1e-10)
    fprintf('  [PASS] c* (employed, median wage) is monotonically increasing in assets.\n');
    n_pass = n_pass + 1;
else
    n_violations = sum(dc_E < -1e-10);
    fprintf('  [FAIL] c* (employed, median wage) is NOT monotone: %d violations.\n', n_violations);
    n_fail = n_fail + 1;
end

% Test 1d: no NaN or Inf
n_test = n_test + 1;
if ~any(isnan(c_star_U)) && ~any(isinf(c_star_U)) && ...
   ~any(isnan(c_star_E)) && ~any(isinf(c_star_E))
    fprintf('  [PASS] No NaN/Inf in c* output.\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] NaN or Inf found in c* output.\n');
    n_fail = n_fail + 1;
end

% Test 1e: verify consistency with inline build_A_1d computation
% build_A_1d computes c_opt internally — check that compute_c_policy
% produces the same result when given the same Va.
n_test = n_test + 1;
income_U_test = par.r * gr.a_sin + par.b_m;
[~, c_inline] = build_A_1d(sol_m.U_sin, gr.a_sin, income_U_test, par);
% build_A_1d uses upwind, so c_inline includes the upwind selection.
% compute_c_policy applied to the forward-difference Va should match cf.
dVf_test = zeros(N_a, 1);
dVf_test(1:N_a-1) = (sol_m.U_sin(2:N_a) - sol_m.U_sin(1:N_a-1)) ./ gr.da_sin;
dVf_test(N_a) = par.u1(income_U_test(N_a));
c_from_policy = compute_c_policy(dVf_test, par);
% These should match par.u1inv(dVf_test)
c_from_u1inv  = par.u1inv(dVf_test);
max_diff = max(abs(c_from_policy - c_from_u1inv));
if max_diff < 1e-12
    fprintf('  [PASS] compute_c_policy matches par.u1inv (max diff = %.2e).\n', max_diff);
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] compute_c_policy differs from par.u1inv (max diff = %.2e).\n', max_diff);
    n_fail = n_fail + 1;
end

%% ===== Test 2: compute_s_policy =====
fprintf('\n--- Test 2: compute_s_policy ---\n');

% Test at several wage levels
test_wages = [1, ceil(N_w/4), ceil(N_w/2), ceil(3*N_w/4), N_w];
s_all_ok = true;
s_nonneg_ok = true;
s_nonan_ok = true;

for idx = 1:length(test_wages)
    iw = test_wages(idx);
    V_current = sol_m.E_sin(iw,:)';
    s_test = compute_s_policy(V_current, sol_m.E_sin, par.gamma_m, par, gr);

    if any(s_test < -1e-14)
        s_nonneg_ok = false;
    end
    if any(isnan(s_test)) || any(isinf(s_test))
        s_nonan_ok = false;
    end
end

% Test 2a: s* >= 0 at all test points
n_test = n_test + 1;
if s_nonneg_ok
    fprintf('  [PASS] s* >= 0 at all test grid points.\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] s* < 0 found at some test grid points.\n');
    n_fail = n_fail + 1;
end

% Test 2b: no NaN or Inf
n_test = n_test + 1;
if s_nonan_ok
    fprintf('  [PASS] No NaN/Inf in s* output.\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] NaN or Inf found in s* output.\n');
    n_fail = n_fail + 1;
end

% Test 2c: s* at highest wage should be 0 (no improving offers)
n_test = n_test + 1;
V_top = sol_m.E_sin(N_w,:)';
s_top = compute_s_policy(V_top, sol_m.E_sin, par.gamma_m, par, gr);
if max(abs(s_top)) < 1e-10
    fprintf('  [PASS] s* = 0 at highest wage (no improving offers).\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] s* != 0 at highest wage (max = %.4e).\n', max(abs(s_top)));
    n_fail = n_fail + 1;
end

% Test 2d: verify consistency with inline solve_single_hjb computation
% Compare s_opt from solve_singles with compute_s_policy at median wage
n_test = n_test + 1;
iw_check = ceil(N_w / 2);
V_check = sol_m.E_sin(iw_check,:)';
s_standalone = compute_s_policy(V_check, sol_m.E_sin, par.gamma_m, par, gr);
s_inline = sol_m.s_opt(iw_check,:)';
max_s_diff = max(abs(s_standalone - s_inline));
if max_s_diff < 1e-8
    fprintf('  [PASS] compute_s_policy matches inline s_opt (max diff = %.2e).\n', max_s_diff);
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] compute_s_policy differs from inline s_opt (max diff = %.2e).\n', max_s_diff);
    n_fail = n_fail + 1;
end

%% ===== Test 3: find_reservation_wage =====
fprintf('\n--- Test 3: find_reservation_wage ---\n');

% Test at several asset levels
test_assets = [1, ceil(N_a/4), ceil(N_a/2), ceil(3*N_a/4), N_a];
wR_in_bounds = true;
wR_residual_ok = true;
wR_nonan = true;
wR_has_flag = true;
bisect_tol = 1e-10;

wR_values = zeros(length(test_assets), 1);

for idx = 1:length(test_assets)
    ia = test_assets(idx);
    W_vec = sol_m.E_sin(:, ia);
    U_val = sol_m.U_sin(ia);

    [wR_test, status] = find_reservation_wage(W_vec, U_val, gr.w, bisect_tol);

    wR_values(idx) = wR_test;

    % Check bounds
    if wR_test < gr.w(1) - 1e-10 || wR_test > gr.w(end) + 1e-10
        wR_in_bounds = false;
    end

    % Check residual (only if bracket was found)
    if status.bracket_found
        if status.residual > bisect_tol * 10  % allow small slack
            wR_residual_ok = false;
        end
    end

    % Check for NaN
    if isnan(wR_test) || isinf(wR_test)
        wR_nonan = false;
    end

    % Check status flag exists
    if ~isfield(status, 'bracket_found') || ~isfield(status, 'flag')
        wR_has_flag = false;
    end
end

% Test 3a: wR within wage grid bounds
n_test = n_test + 1;
if wR_in_bounds
    fprintf('  [PASS] wR falls within wage grid bounds at all test points.\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] wR outside wage grid bounds at some test points.\n');
    n_fail = n_fail + 1;
end

% Test 3b: residual < tol where bracket was found
n_test = n_test + 1;
if wR_residual_ok
    fprintf('  [PASS] |W(wR) - U| < tol at all bracketed test points.\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] |W(wR) - U| exceeds tolerance at some test points.\n');
    n_fail = n_fail + 1;
end

% Test 3c: no NaN or Inf
n_test = n_test + 1;
if wR_nonan
    fprintf('  [PASS] No NaN/Inf in wR output.\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] NaN or Inf found in wR output.\n');
    n_fail = n_fail + 1;
end

% Test 3d: status flag exists
n_test = n_test + 1;
if wR_has_flag
    fprintf('  [PASS] Status struct includes bracket_found and flag fields.\n');
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] Status struct missing expected fields.\n');
    n_fail = n_fail + 1;
end

% Test 3e: verify consistency with solve_singles reservation wages
n_test = n_test + 1;
wR_standalone_all = zeros(N_a, 1);
for ia = 1:N_a
    [wR_standalone_all(ia), ~] = find_reservation_wage(sol_m.E_sin(:,ia), ...
        sol_m.U_sin(ia), gr.w, bisect_tol);
end
max_wR_diff = max(abs(wR_standalone_all - sol_m.wR_sin));
if max_wR_diff < 1e-6
    fprintf('  [PASS] find_reservation_wage matches solve_singles wR (max diff = %.2e).\n', max_wR_diff);
    n_pass = n_pass + 1;
else
    fprintf('  [FAIL] find_reservation_wage differs from solve_singles wR (max diff = %.2e).\n', max_wR_diff);
    n_fail = n_fail + 1;
end

%% ===== Summary =====
fprintf('\n============================================\n');
fprintf('  Results: %d / %d tests passed', n_pass, n_test);
if n_fail > 0
    fprintf(' (%d FAILED)', n_fail);
end
fprintf('\n============================================\n');

% Print sample values for inspection
fprintf('\nSample c* (unemployed, first 5 asset points):\n');
fprintf('  a = [');  fprintf('%.2f ', gr.a_sin(1:min(5,N_a)));  fprintf(']\n');
fprintf('  c*= [');  fprintf('%.4f ', c_star_U(1:min(5,N_a)));  fprintf(']\n');

fprintf('\nSample s* (median wage, first 5 asset points):\n');
s_mid = compute_s_policy(sol_m.E_sin(ceil(N_w/2),:)', sol_m.E_sin, par.gamma_m, par, gr);
fprintf('  s*= [');  fprintf('%.4f ', s_mid(1:min(5,N_a)));  fprintf(']\n');

fprintf('\nSample wR (first 5 asset points):\n');
fprintf('  a  = [');  fprintf('%.2f ', gr.a_sin(1:min(5,N_a)));  fprintf(']\n');
fprintf('  wR = [');  fprintf('%.4f ', wR_standalone_all(1:min(5,N_a)));  fprintf(']\n');
