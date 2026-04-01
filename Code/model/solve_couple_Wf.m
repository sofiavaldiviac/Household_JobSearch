function [Wf, c_Wf, s_Wf] = solve_couple_Wf(Wf, UU, EE, Wm, Vd_m, Vd_f, par, gr)
% SOLVE_COUPLE_WF  One implicit HJB step for worker-searcher (f employed).
%
%   Symmetric to solve_couple_Wm with m <-> f exchanged.
%
%   Wf : N_w x N3  value W_f(w_f, aJ, am, af)
%   UU : N3 x 1    dual-unemployed value
%   EE : N_w x N_w x N3  dual-employed value (wm, wf, 3d)
%   Wm : N_w x N3  worker-searcher value (m employed), for breadwinner
%   Vd_m, Vd_f : N3 x 1 divorce values

    N3  = gr.N3;
    N_w = gr.N_w;

    c_Wf = zeros(N_w, N3);
    s_Wf = zeros(N_w, N3);

    [ii, jj, kk] = ndgrid(1:gr.N_aJ, 1:gr.N_am, 1:gr.N_af);
    a_total = gr.aJ(ii(:)) + gr.am(jj(:)) + gr.af(kk(:));

    for iw = 1:N_w
        w_f = gr.w(iw);

        % Flow income: r*a_total + b_m + w_f
        income = par.r * a_total + par.b_m + w_f;

        [A, c_iw] = build_A_3d(Wf(iw,:)', income, par, gr);
        c_Wf(iw,:) = c_iw';

        % Job destruction inflow: delta_f * UU  (the -delta_f*Wf goes onto B diagonal)
        inflow_destroy = par.delta_f * UU;

        % OTJ search for f: gain from w' > w_f
        OTJ_gain = zeros(N3, 1);
        for jw = iw+1:N_w
            OTJ_gain = OTJ_gain + max(Wf(jw,:)' - Wf(iw,:)', 0) ...
                       .* gr.f_w(jw) .* gr.qw(jw);
        end

        s_iw = (par.gamma_f * OTJ_gain / (par.kappa0 * par.kappa1)).^(1/(par.kappa1-1));
        s_iw = real(max(s_iw, 0));
        s_iw = min(s_iw, 10);
        s_Wf(iw,:) = s_iw';

        % Combined OTJ net value (non-negative)
        net_otj = max(s_iw .* par.gamma_f .* OTJ_gain - par.kappa0 * s_iw.^par.kappa1, 0);

        % Male finds job: lambda_m * integral max{E(w_m,w_f,.) - Wf(w_f,.),
        %                                          Wm(w_m,.) - Wf(w_f,.), 0} dF(w_m)
        m_job_val = zeros(N3, 1);
        for jw = 1:N_w
            E_val  = squeeze(EE(jw, iw, :));   % E(w_m=jw, w_f=iw, .)
            Wm_val = Wm(jw,:)';
            best   = max(max(E_val, Wm_val), Wf(iw,:)');
            m_job_val = m_job_val + (best - Wf(iw,:)') .* gr.f_w(jw) .* gr.qw(jw);
        end
        m_job_val = par.lambda_m * max(m_job_val, 0);

        % Divorce inflow (the -pi*Wf goes onto B diagonal)
        div_val = par.pi_div * (Vd_m(:) + Vd_f(:));

        % Flow
        flow = par.u(c_iw) + inflow_destroy + net_otj + m_job_val + div_val;

        % Implicit update
        B = (1/par.Delta_t + par.rho + par.delta_f + par.pi_div) * speye(N3) - A;
        rhs = flow + (1/par.Delta_t) * Wf(iw,:)';

        Wf(iw,:) = (B \ rhs)';
    end

end
