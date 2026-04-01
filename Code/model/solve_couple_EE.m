function [EE, c_EE, s_EE_m, s_EE_f] = solve_couple_EE(EE, Wm, Wf, Vd_m, Vd_f, par, gr)
% SOLVE_COUPLE_EE  One implicit HJB step for dual-employed couples.
%
%   EE : N_w x N_w x N3  value E(w_m, w_f, aJ, am, af)
%   Wm : N_w x N3  worker-searcher (m employed)
%   Wf : N_w x N3  worker-searcher (f employed)
%   Vd_m, Vd_f : N3 x 1 divorce values
%
%   For each (w_m, w_f) pair, solves the 3D HJB on (aJ, am, af).

    N3  = gr.N3;
    N_w = gr.N_w;

    c_EE   = zeros(N_w, N_w, N3);
    s_EE_m = zeros(N_w, N_w, N3);
    s_EE_f = zeros(N_w, N_w, N3);

    [ii, jj, kk] = ndgrid(1:gr.N_aJ, 1:gr.N_am, 1:gr.N_af);
    a_total = gr.aJ(ii(:)) + gr.am(jj(:)) + gr.af(kk(:));

    for iw_m = 1:N_w
        for iw_f = 1:N_w
            w_m = gr.w(iw_m);
            w_f = gr.w(iw_f);

            % Flow income
            income = par.r * a_total + w_m + w_f;

            % Build drift matrix
            V_curr = squeeze(EE(iw_m, iw_f, :));
            [A, c_ij] = build_A_3d(V_curr, income, par, gr);
            c_EE(iw_m, iw_f, :) = c_ij;

            % Job destruction inflow (the -delta*EE terms go onto B diagonal)
            inflow_dest_m = par.delta_m * Wf(iw_f,:)';
            inflow_dest_f = par.delta_f * Wm(iw_m,:)';

            % OTJ search for m: offers w' > w_m
            OTJ_m = zeros(N3, 1);
            for jw = iw_m+1:N_w
                % Accept at EE(w',wf) or breadwinner Wm(w') or reject
                E_new  = squeeze(EE(jw, iw_f, :));
                Wm_new = Wm(jw,:)';
                best   = max(max(E_new, Wm_new), V_curr);
                OTJ_m  = OTJ_m + (best - V_curr) .* gr.f_w(jw) .* gr.qw(jw);
            end

            s_m = (par.gamma_m * OTJ_m / (par.kappa0 * par.kappa1)).^(1/(par.kappa1-1));
            s_m = real(max(s_m, 0));
            s_m = min(s_m, 10);
            s_EE_m(iw_m, iw_f, :) = s_m;

            % OTJ search for f: offers w' > w_f
            OTJ_f = zeros(N3, 1);
            for jw = iw_f+1:N_w
                E_new  = squeeze(EE(iw_m, jw, :));
                Wf_new = Wf(jw,:)';
                best   = max(max(E_new, Wf_new), V_curr);
                OTJ_f  = OTJ_f + (best - V_curr) .* gr.f_w(jw) .* gr.qw(jw);
            end

            s_f = (par.gamma_f * OTJ_f / (par.kappa0 * par.kappa1)).^(1/(par.kappa1-1));
            s_f = real(max(s_f, 0));
            s_f = min(s_f, 10);
            s_EE_f(iw_m, iw_f, :) = s_f;

            % Combined OTJ net values (non-negative)
            net_otj_m = max(s_m .* par.gamma_m .* OTJ_m - par.kappa0 * s_m.^par.kappa1, 0);
            net_otj_f = max(s_f .* par.gamma_f .* OTJ_f - par.kappa0 * s_f.^par.kappa1, 0);

            % Divorce inflow (the -pi*EE goes onto B diagonal)
            div_val = par.pi_div * (Vd_m(:) + Vd_f(:));

            % Flow
            flow = par.u(c_ij) + inflow_dest_m + inflow_dest_f ...
                 + net_otj_m + net_otj_f + div_val;

            % Implicit update
            B = (1/par.Delta_t + par.rho + par.delta_m + par.delta_f + par.pi_div) * speye(N3) - A;
            rhs = flow + (1/par.Delta_t) * V_curr;

            EE(iw_m, iw_f, :) = B \ rhs;
        end
    end

end
