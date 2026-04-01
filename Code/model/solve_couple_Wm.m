function [Wm, c_Wm, s_Wm] = solve_couple_Wm(Wm, UU, EE, Wf, Vd_m, Vd_f, par, gr)
% SOLVE_COUPLE_WM  One implicit HJB step for worker-searcher (m employed).
%
%   Wm : N_w x N3  value W_m(w_m, aJ, am, af)
%   UU : N3 x 1    dual-unemployed value
%   EE : N_w x N_w x N3  dual-employed value (indexed: wm, wf, 3d)
%          -- only the EE(iw_m, :, :) slices matter for f's acceptance
%   Wf : N_w x N3  worker-searcher value (f employed), for breadwinner
%   Vd_m, Vd_f : N3 x 1 divorce values
%
%   For each wage w_m on the grid, solves the 3D HJB on (aJ, am, af).

    N3  = gr.N3;
    N_w = gr.N_w;

    c_Wm = zeros(N_w, N3);
    s_Wm = zeros(N_w, N3);

    % Precompute total assets for income
    [ii, jj, kk] = ndgrid(1:gr.N_aJ, 1:gr.N_am, 1:gr.N_af);
    a_total = gr.aJ(ii(:)) + gr.am(jj(:)) + gr.af(kk(:));

    for iw = 1:N_w
        w_m = gr.w(iw);

        % Flow income: r*a_total + w_m + b_f
        income = par.r * a_total + w_m + par.b_f;

        % Build drift matrix
        [A, c_iw] = build_A_3d(Wm(iw,:)', income, par, gr);
        c_Wm(iw,:) = c_iw';

        % Job destruction inflow: delta_m * UU  (the -delta_m*Wm goes onto B diagonal)
        inflow_destroy = par.delta_m * UU;

        % OTJ search: gain from offers w' > w_m
        OTJ_gain = zeros(N3, 1);
        for jw = iw+1:N_w
            OTJ_gain = OTJ_gain + max(Wm(jw,:)' - Wm(iw,:)', 0) ...
                       .* gr.f_w(jw) .* gr.qw(jw);
        end

        % Optimal search intensity (capped to prevent runaway)
        s_iw = (par.gamma_m * OTJ_gain / (par.kappa0 * par.kappa1)).^(1/(par.kappa1-1));
        s_iw = real(max(s_iw, 0));
        s_iw = min(s_iw, 10);
        s_Wm(iw,:) = s_iw';

        % Combined OTJ net value (non-negative)
        net_otj = max(s_iw .* par.gamma_m .* OTJ_gain - par.kappa0 * s_iw.^par.kappa1, 0);

        % Female finds job: lambda_f * integral max{E(w_m,w_f,.) - Wm(w_m,.),
        %                                           Wf(w_f,.) - Wm(w_m,.), 0} dF(w_f)
        f_job_val = zeros(N3, 1);
        for jw = 1:N_w
            % Value of both employed
            E_val = squeeze(EE(iw, jw, :));
            % Value of breadwinner cycle (f works, m quits)
            Wf_val = Wf(jw,:)';
            % Best option for the couple
            best = max(max(E_val, Wf_val), Wm(iw,:)');
            f_job_val = f_job_val + (best - Wm(iw,:)') .* gr.f_w(jw) .* gr.qw(jw);
        end
        f_job_val = par.lambda_f * max(f_job_val, 0);

        % Divorce inflow (the -pi*Wm goes onto B diagonal)
        div_val = par.pi_div * (Vd_m(:) + Vd_f(:));

        % Flow
        flow = par.u(c_iw) + inflow_destroy + net_otj + f_job_val + div_val;

        % Implicit update
        B = (1/par.Delta_t + par.rho + par.delta_m + par.pi_div) * speye(N3) - A;
        rhs = flow + (1/par.Delta_t) * Wm(iw,:)';

        Wm(iw,:) = (B \ rhs)';
    end

end
