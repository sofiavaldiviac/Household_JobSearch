function [sol_m, sol_f] = solve_singles(par, gr)
% SOLVE_SINGLES  Solve the singles problem for both genders.
%
%   [sol_m, sol_f] = solve_singles(par, gr)
%
%   Each output struct contains:
%     U_sin  : N_a x 1     (unemployed value)
%     E_sin  : N_w x N_a   (employed value)
%     c_U    : N_a x 1     (consumption, unemployed)
%     c_E    : N_w x N_a   (consumption, employed)
%     s_opt  : N_w x N_a   (OTJ search intensity)
%     wR_sin : N_a x 1     (reservation wage at each asset level)

    fprintf('=== Solving singles problem ===\n');

    %% --- Male ---
    fprintf('  Male singles...\n');
    sol_m = solve_one_gender(par.b_m, par.lambda_m, par.gamma_m, par.delta_m, par, gr);

    %% --- Female ---
    fprintf('  Female singles...\n');
    sol_f = solve_one_gender(par.b_f, par.lambda_f, par.gamma_f, par.delta_f, par, gr);

    fprintf('=== Singles done ===\n\n');
end

function sol = solve_one_gender(b_i, lambda_i, gamma_i, delta_i, par, gr)
% Solve for one gender's singles problem.
%
%   Convergence strategy (task_02, 2026-03-30):
%   1. Poisson outflow rates treated implicitly in solve_single_hjb
%      (the primary convergence fix — see solve_single_hjb.m header).
%   2. Fixed relaxation every iteration: V = omega*V_hjb + (1-omega)*V_old
%      where omega = 1 - par.damp.  This stabilises oscillatory modes
%      (negative eigenvalues of the Jacobian) that adaptive damping misses
%      because adaptive damping alternates on/off and compares damped
%      against undamped error norms inconsistently.

    N_a = gr.N_a_sin;
    N_w = gr.N_w;
    omega = 1 - par.damp;   % relaxation weight on the new HJB step

    %% Initialize from flow values
    % Unemployed: u(r*a + b) / rho
    income_U = max(par.r * gr.a_sin + b_i, 1e-6);
    U_sin = par.u(income_U) / par.rho;

    % Employed: u(r*a + w) / rho for each wage
    E_sin = zeros(N_w, N_a);
    for iw = 1:N_w
        income_E = max(par.r * gr.a_sin + gr.w(iw), 1e-6);
        E_sin(iw,:) = (par.u(income_E) / par.rho)';
    end

    %% Outer iteration
    %  The coupled solver in solve_single_hjb solves E and U simultaneously,
    %  so the E-U coupling is treated implicitly.  The outer loop only needs
    %  to update the nonlinear terms (consumption policy, search intensity,
    %  acceptance sets) which change between iterates.
    for iter = 1:par.max_outer
        U_old = U_sin;
        E_old = E_sin;

        [U_hjb, E_hjb, ~, ~, ~] = solve_single_hjb(U_sin, E_sin, ...
            b_i, lambda_i, gamma_i, delta_i, par, gr);

        % Check for NaN / Inf
        if any(isnan(U_hjb)) || any(isinf(U_hjb)) || ...
           any(isnan(E_hjb(:))) || any(isinf(E_hjb(:)))
            fprintf('    ERROR: NaN/Inf at iter %d — aborting\n', iter);
            break
        end

        % Fixed relaxation
        U_sin = (1 - omega) * U_old + omega * U_hjb;
        E_sin = (1 - omega) * E_old + omega * E_hjb;

        err_U = max(abs(U_sin - U_old));
        err_E = max(abs(E_sin(:) - E_old(:)));
        err   = max(err_U, err_E);

        if mod(iter, 10) == 0 || iter <= 5
            fprintf('    iter %4d: err = %.2e  (err_U=%.2e, err_E=%.2e)\n', ...
                    iter, err, err_U, err_E);
        end

        if err < par.tol_outer
            fprintf('    Converged at iter %d (err = %.2e)\n', iter, err);
            break
        end
    end

    if iter == par.max_outer && err >= par.tol_outer
        fprintf('    WARNING: did not converge (err = %.2e)\n', err);
    end

    if iter == par.max_outer && err >= par.tol_outer
        fprintf('    WARNING: did not converge (err = %.2e)\n', err);
    end

    %% Recompute policies at converged (U_sin, E_sin) for consistency
    %  The last HJB call inside the loop used the pre-relaxation values.
    %  One final call ensures c_U, c_E, s_opt match the stored value fns.
    [~, ~, c_U, c_E, s_opt] = solve_single_hjb(U_sin, E_sin, ...
        b_i, lambda_i, gamma_i, delta_i, par, gr);

    %% Compute reservation wages using find_reservation_wage (task_02 fix)
    %  Replaced inline compute_single_resw with the more robust
    %  find_reservation_wage function that uses bisection after bracketing.
    %  See find_reservation_wage.m for algorithm details and status flags.
    wR_sin = zeros(N_a, 1);
    for ia = 1:N_a
        [wR_sin(ia), ~] = find_reservation_wage(E_sin(:, ia), U_sin(ia), gr.w);
    end

    %% Pack output
    sol.U_sin  = U_sin;
    sol.E_sin  = E_sin;
    sol.c_U    = c_U;
    sol.c_E    = c_E;
    sol.s_opt  = s_opt;
    sol.wR_sin = wR_sin;
end
