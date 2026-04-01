function [U_sin, E_sin, c_U, c_E, s_opt] = solve_single_hjb(U_sin, E_sin, ...
    b_i, lambda_i, gamma_i, delta_i, par, gr)
% SOLVE_SINGLE_HJB  One implicit HJB step for singles (coupled system).
%
%   Solves for E_sin(w,a) and U_sin(a) SIMULTANEOUSLY, including:
%     - E-U coupling   (delta for job destruction, lambda for job finding)
%     - E-E coupling   (OTJ search: inflow from higher wages)
%   inside a single sparse linear system.  Only the consumption/savings
%   policy (upwind A matrix), search intensity s, and acceptance sets are
%   evaluated at the current iterate (outer loop updates these).
%
%   System size: (N_w + 1) * N_a.  Sparse direct solve.

    N_a = gr.N_a_sin;
    N_w = gr.N_w;
    n_total = (N_w + 1) * N_a;

    %% ====== Compute policies from current iterate ======
    c_E   = zeros(N_w, N_a);
    s_opt = zeros(N_w, N_a);

    % Storage for per-wage quantities needed for the system
    A_E_cell = cell(N_w, 1);   % drift matrices
    c_E_cell = cell(N_w, 1);   % consumption
    s_cell   = cell(N_w, 1);   % search intensity
    OTJ_gain_cell = cell(N_w, 1);
    otj_accept_cell = cell(N_w, 1);  % N_a x N_w: accept(jw) for each iw

    for iw = 1:N_w
        income_E = par.r * gr.a_sin + gr.w(iw);
        [A_E_cell{iw}, c_iw] = build_A_1d(E_sin(iw,:)', gr.a_sin, income_E, par);
        c_E(iw,:) = c_iw';
        c_E_cell{iw} = c_iw;

        % OTJ gain and acceptance at each higher wage
        OTJ_gain = zeros(N_a, 1);
        acc = zeros(N_a, N_w);  % acc(:,jw) = 1 where E(jw)>E(iw)
        for jw = iw+1:N_w
            gain_jw = max(E_sin(jw,:)' - E_sin(iw,:)', 0);
            OTJ_gain = OTJ_gain + gain_jw .* gr.f_w(jw) .* gr.qw(jw);
            acc(:,jw) = double(E_sin(jw,:)' > E_sin(iw,:)');
        end
        OTJ_gain_cell{iw} = OTJ_gain;
        otj_accept_cell{iw} = acc;

        % Optimal search intensity (capped to prevent runaway during iteration)
        s_iw = real((gamma_i * OTJ_gain / (par.kappa0 * par.kappa1)) ...
               .^(1/(par.kappa1-1)));
        s_iw = max(s_iw, 0);
        s_iw = min(s_iw, 10);  % cap: steady-state s is O(1-3)
        s_opt(iw,:) = s_iw';
        s_cell{iw} = s_iw;
    end

    %% ====== Build the coupled system ======
    % Ordering: x = [E(1,:)'; E(2,:)'; ...; E(N_w,:)'; U(:)]

    % Estimate nnz conservatively
    est_nnz = (N_w + 1) * 5 * N_a + N_w * N_w * N_a;
    II = zeros(est_nnz, 1);
    JJ = zeros(est_nnz, 1);
    VV = zeros(est_nnz, 1);
    ptr = 0;
    rhs_big = zeros(n_total, 1);

    U_offset = N_w * N_a;

    for iw = 1:N_w
        E_offset_iw = (iw - 1) * N_a;
        s_iw = s_cell{iw};
        acc  = otj_accept_cell{iw};

        % --- OTJ outflow rate: s*gamma * sum_{accepted jw>iw} f(jw)*dw(jw)
        otj_outflow = zeros(N_a, 1);
        for jw = iw+1:N_w
            otj_outflow = otj_outflow + acc(:,jw) .* gr.f_w(jw) .* gr.qw(jw);
        end
        otj_outflow = s_iw .* gamma_i .* otj_outflow;

        % --- Diagonal block: B_E(iw) = (1/dt + rho + delta + otj_outflow)*I - A
        B_diag = (1/par.Delta_t + par.rho + delta_i) * speye(N_a) ...
                 + spdiags(otj_outflow, 0, N_a, N_a) - A_E_cell{iw};
        [ri, ci, vi] = find(B_diag);
        idx = ptr + (1:length(ri));
        II(idx) = ri + E_offset_iw;
        JJ(idx) = ci + E_offset_iw;
        VV(idx) = vi;
        ptr = ptr + length(ri);

        % --- Off-diag: OTJ inflow E(iw) <- E(jw):  -s*gamma*f(jw)*dw(jw)*accept
        for jw = iw+1:N_w
            E_offset_jw = (jw - 1) * N_a;
            for ia = 1:N_a
                if acc(ia, jw) > 0
                    coeff = -s_iw(ia) * gamma_i * gr.f_w(jw) * gr.qw(jw);
                    if coeff ~= 0
                        ptr = ptr + 1;
                        II(ptr) = E_offset_iw + ia;
                        JJ(ptr) = E_offset_jw + ia;
                        VV(ptr) = coeff;
                    end
                end
            end
        end

        % --- Off-diag: E(iw) <- U:  -delta * I
        for ia = 1:N_a
            ptr = ptr + 1;
            II(ptr) = E_offset_iw + ia;
            JJ(ptr) = U_offset + ia;
            VV(ptr) = -delta_i;
        end

        % --- RHS for E(iw): u(c) - kappa(s) + (1/dt)*E_old
        search_cost = par.kappa0 * s_iw.^par.kappa1;
        rhs_big(E_offset_iw + (1:N_a)) = par.u(c_E_cell{iw}) - search_cost ...
                                          + (1/par.Delta_t) * E_sin(iw,:)';
    end

    %% --- U block ---
    income_U = par.r * gr.a_sin + b_i;
    [A_U, c_U] = build_A_1d(U_sin, gr.a_sin, income_U, par);

    accept_U = zeros(N_w, N_a);
    accept_prob = zeros(N_a, 1);
    for iw = 1:N_w
        accept_U(iw,:) = double(E_sin(iw,:) > U_sin');
        accept_prob = accept_prob + accept_U(iw,:)' .* gr.f_w(iw) .* gr.qw(iw);
    end

    % Diagonal: B_U = (1/dt + rho + lambda*accept_prob)*I - A_U
    B_U = (1/par.Delta_t + par.rho) * speye(N_a) ...
          + spdiags(lambda_i * accept_prob, 0, N_a, N_a) - A_U;
    [ri, ci, vi] = find(B_U);
    idx = ptr + (1:length(ri));
    II(idx) = ri + U_offset;
    JJ(idx) = ci + U_offset;
    VV(idx) = vi;
    ptr = ptr + length(ri);

    % Off-diag: U <- E(iw):  -lambda * accept * f * dw
    for iw = 1:N_w
        E_offset_iw = (iw - 1) * N_a;
        for ia = 1:N_a
            if accept_U(iw, ia) > 0
                ptr = ptr + 1;
                II(ptr) = U_offset + ia;
                JJ(ptr) = E_offset_iw + ia;
                VV(ptr) = -lambda_i * gr.f_w(iw) * gr.qw(iw);
            end
        end
    end

    % RHS for U: u(c_U) + (1/dt)*U_old
    rhs_big(U_offset + (1:N_a)) = par.u(c_U) + (1/par.Delta_t) * U_sin;

    %% ====== Solve ======
    II = II(1:ptr);
    JJ = JJ(1:ptr);
    VV = VV(1:ptr);
    B_big = sparse(II, JJ, VV, n_total, n_total);

    x = B_big \ rhs_big;

    %% ====== Unpack ======
    for iw = 1:N_w
        E_sin(iw,:) = x((iw-1)*N_a + (1:N_a))';
    end
    U_sin = x(N_w*N_a + (1:N_a));

end
