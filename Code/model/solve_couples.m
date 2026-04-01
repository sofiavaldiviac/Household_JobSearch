function sol = solve_couples(sol_m, sol_f, theta, par, gr)
% SOLVE_COUPLES  Outer iteration for the couples problem.
%
%   sol = solve_couples(sol_m, sol_f, theta, par, gr)
%
%   sol_m, sol_f : singles solutions (from solve_singles)
%   theta        : 'O' (universal) or 'L' (limited)
%
%   Returns struct with UU, Wm, Wf, EE and policy functions.

    fprintf('=== Solving couples problem (theta = %s) ===\n', theta);

    N3  = gr.N3;
    N_w = gr.N_w;

    %% Step 1: Compute divorce values
    fprintf('  Computing divorce values...\n');
    [Vd_m, Vd_f] = compute_divorce_values(sol_m, sol_f, theta, par, gr);
    Vd_m = Vd_m(:);
    Vd_f = Vd_f(:);

    %% Step 2: Initialize value functions from flow values
    [ii, jj, kk] = ndgrid(1:gr.N_aJ, 1:gr.N_am, 1:gr.N_af);
    a_total = gr.aJ(ii(:)) + gr.am(jj(:)) + gr.af(kk(:));

    % UU: flow = u(r*a + b_m + b_f) / rho
    income_UU = max(par.r * a_total + par.b_m + par.b_f, 1e-6);
    UU = par.u(income_UU) / par.rho;

    % Wm(w_m, .): flow = u(r*a + w_m + b_f) / rho
    Wm = zeros(N_w, N3);
    for iw = 1:N_w
        inc = max(par.r * a_total + gr.w(iw) + par.b_f, 1e-6);
        Wm(iw,:) = (par.u(inc) / par.rho)';
    end

    % Wf(w_f, .): flow = u(r*a + b_m + w_f) / rho
    Wf = zeros(N_w, N3);
    for iw = 1:N_w
        inc = max(par.r * a_total + par.b_m + gr.w(iw), 1e-6);
        Wf(iw,:) = (par.u(inc) / par.rho)';
    end

    % EE(w_m, w_f, .): flow = u(r*a + w_m + w_f) / rho
    EE = zeros(N_w, N_w, N3);
    for iw_m = 1:N_w
        for iw_f = 1:N_w
            inc = max(par.r * a_total + gr.w(iw_m) + gr.w(iw_f), 1e-6);
            EE(iw_m, iw_f, :) = par.u(inc) / par.rho;
        end
    end

    %% Step 3: Outer iteration
    %  Fixed relaxation every iteration (same pattern as solve_singles.m):
    %  V = (1-omega)*V_old + omega*V_hjb, where omega = 1 - par.damp.
    omega = 1 - par.damp;

    % --- diagnostics (task_05b) ---
    diagn_dir = fullfile(fileparts(mfilename('fullpath')), 'diagnostics', 'task_05b');
    if ~exist(diagn_dir, 'dir'), mkdir(diagn_dir); end
    diags.iter = [];
    diags.err_UU = [];
    diags.err_Wm = [];
    diags.err_Wf = [];
    diags.err_EE = [];
    diags.err = [];
    diags.timestamps = {};
    % ----------------------------

    for iter = 1:par.max_outer
        UU_old = UU;
        Wm_old = Wm;
        Wf_old = Wf;
        EE_old = EE;

        % Solve UU
        [UU, c_UU] = solve_couple_UU(UU, Wm, Wf, Vd_m, Vd_f, par, gr);
        if any(isnan(UU)) || any(isinf(UU))
            fprintf('    ERROR: NaN/Inf in UU at iter %d — aborting\n', iter);
            break
        end

        % Solve Wm for each w_m
        [Wm, c_Wm, s_Wm] = solve_couple_Wm(Wm, UU, EE, Wf, Vd_m, Vd_f, par, gr);
        if any(isnan(Wm(:))) || any(isinf(Wm(:)))
            fprintf('    ERROR: NaN/Inf in Wm at iter %d — aborting\n', iter);
            break
        end

        % Solve Wf for each w_f
        [Wf, c_Wf, s_Wf] = solve_couple_Wf(Wf, UU, EE, Wm, Vd_m, Vd_f, par, gr);
        if any(isnan(Wf(:))) || any(isinf(Wf(:)))
            fprintf('    ERROR: NaN/Inf in Wf at iter %d — aborting\n', iter);
            break
        end

        % Solve EE for each (w_m, w_f)
        [EE, c_EE, s_EE_m, s_EE_f] = solve_couple_EE(EE, Wm, Wf, Vd_m, Vd_f, par, gr);
        if any(isnan(EE(:))) || any(isinf(EE(:)))
            fprintf('    ERROR: NaN/Inf in EE at iter %d — aborting\n', iter);
            break
        end

        % Fixed relaxation
        UU = (1-omega)*UU_old + omega*UU;
        Wm = (1-omega)*Wm_old + omega*Wm;
        Wf = (1-omega)*Wf_old + omega*Wf;
        EE = (1-omega)*EE_old + omega*EE;

        % Convergence check (on damped values)
        err_UU = max(abs(UU - UU_old));
        err_Wm = max(abs(Wm(:) - Wm_old(:)));
        err_Wf = max(abs(Wf(:) - Wf_old(:)));
        err_EE = max(abs(EE(:) - EE_old(:)));
        err    = max([err_UU, err_Wm, err_Wf, err_EE]);

        if mod(iter,5) == 0 || iter == 1
            fprintf('  iter %3d: err_UU=%.2e  err_Wm=%.2e  err_Wf=%.2e  err_EE=%.2e\n', ...
                iter, err_UU, err_Wm, err_Wf, err_EE);
        end

        % --- diagnostics (task_05b): record ---
        diags.iter(end+1) = iter;
        diags.err_UU(end+1) = err_UU;
        diags.err_Wm(end+1) = err_Wm;
        diags.err_Wf(end+1) = err_Wf;
        diags.err_EE(end+1) = err_EE;
        diags.err(end+1) = err;
        diags.timestamps{end+1} = datestr(now);
        if mod(iter,5)==0 || any(isnan([err_UU,err_Wm,err_Wf,err_EE])) || any(isinf([err_UU,err_Wm,err_Wf,err_EE]))
            save(fullfile(diagn_dir,'diagnostics_task_05b.mat'),'diags');
        end
        % If NaN/Inf found in value functions, save snapshot and break
        if any(isnan(UU(:))) || any(isinf(UU(:))) || any(isnan(Wm(:))) || any(isinf(Wm(:))) || any(isnan(Wf(:))) || any(isinf(Wf(:))) || any(isnan(EE(:))) || any(isinf(EE(:)))
            save(fullfile(diagn_dir,sprintf('snapshot_iter_%03d.mat',iter)), 'UU','Wm','Wf','EE','iter','diags');
            fprintf('  Snapshot saved at iter %d due to NaN/Inf\n', iter);
            break
        end
        % ---------------------------------

        if err < par.tol_outer
            fprintf('  Converged at iter %d (err = %.2e)\n', iter, err);
            % --- diagnostics (task_05b): final save on convergence ---
            save(fullfile(diagn_dir,'diagnostics_task_05b.mat'),'diags');
            % ---------------------------------------------------------
            break
        end
    end

    % --- diagnostics (task_05b): final save ---
    save(fullfile(diagn_dir,'diagnostics_task_05b.mat'),'diags');
    % ------------------------------------------

    if iter == par.max_outer && err >= par.tol_outer
        fprintf('  WARNING: did not converge (err = %.2e)\n', err);
    end

    %% Pack output
    sol.UU    = UU;
    sol.Wm    = Wm;
    sol.Wf    = Wf;
    sol.EE    = EE;
    sol.c_UU  = c_UU;
    sol.c_Wm  = c_Wm;
    sol.c_Wf  = c_Wf;
    sol.c_EE  = c_EE;
    sol.s_Wm  = s_Wm;
    sol.s_Wf  = s_Wf;
    sol.s_EE_m = s_EE_m;
    sol.s_EE_f = s_EE_f;
    sol.Vd_m  = Vd_m;
    sol.Vd_f  = Vd_f;
    sol.theta = theta;

    fprintf('=== Couples done (theta = %s) ===\n\n', theta);
end
