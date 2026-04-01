function [UU, c_UU] = solve_couple_UU(UU, Wm, Wf, Vd_m, Vd_f, par, gr)
% SOLVE_COUPLE_UU  One implicit HJB step for dual-unemployed couples.
%
%   UU : N3 x 1  value function U(aJ, am, af) in lexicographic order
%   Wm : N_w x N3  worker-searcher value (m employed)
%   Wf : N_w x N3  worker-searcher value (f employed)
%   Vd_m, Vd_f : N3 x 1  divorce values
%
%   Returns updated UU and optimal consumption c_UU.

    N3 = gr.N3;

    %% Flow income: r*(aJ + am + af) + b_m + b_f
    [ii, jj, kk] = ndgrid(1:gr.N_aJ, 1:gr.N_am, 1:gr.N_af);
    a_total = gr.aJ(ii(:)) + gr.am(jj(:)) + gr.af(kk(:));
    income = par.r * a_total + par.b_m + par.b_f;

    %% Build 3D drift matrix
    [A, c_UU] = build_A_3d(UU, income, par, gr);

    %% Option value: male finds job
    % lambda_m * integral max{Wm(w, .) - UU(.), 0} dF(w)
    job_val_m = zeros(N3, 1);
    for iw = 1:gr.N_w
        job_val_m = job_val_m + max(Wm(iw,:)' - UU, 0) .* gr.f_w(iw) .* gr.qw(iw);
    end
    job_val_m = par.lambda_m * job_val_m;

    %% Option value: female finds job
    job_val_f = zeros(N3, 1);
    for iw = 1:gr.N_w
        job_val_f = job_val_f + max(Wf(iw,:)' - UU, 0) .* gr.f_w(iw) .* gr.qw(iw);
    end
    job_val_f = par.lambda_f * job_val_f;

    %% Divorce option value: pi * [Vd_m + Vd_f]  (the -pi*UU goes onto B diagonal)
    div_val = par.pi_div * (Vd_m(:) + Vd_f(:));

    %% Flow utility + option values
    flow = par.u(c_UU) + job_val_m + job_val_f + div_val;

    %% Implicit update
    B = (1/par.Delta_t + par.rho + par.pi_div) * speye(N3) - A;
    rhs = flow + (1/par.Delta_t) * UU;

    UU = B \ rhs;

end
