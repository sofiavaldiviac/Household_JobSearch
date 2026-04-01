function res = compute_reservation_wages(sol, par, gr)
% COMPUTE_RESERVATION_WAGES  Find reservation wages from converged values.
%
%   res = compute_reservation_wages(sol, par, gr)
%
%   sol : output struct from solve_couples (has UU, Wm, Wf)
%
%   Returns struct with:
%     wR_m : N_aJ x N_am x N_af  male reservation wage in couple
%     wR_f : N_aJ x N_am x N_af  female reservation wage in couple

    N_aJ = gr.N_aJ;
    N_am = gr.N_am;
    N_af = gr.N_af;
    N_w  = gr.N_w;

    wR_m = zeros(N_aJ, N_am, N_af);
    wR_f = zeros(N_aJ, N_am, N_af);

    for i = 1:N_aJ
        for j = 1:N_am
            for k = 1:N_af
                n = i + (j-1)*N_aJ + (k-1)*N_aJ*N_am;
                U_val = sol.UU(n);

                %% Male reservation wage: W_m(wR, aJ, am, af) = U(aJ, am, af)
                [wR_m(i,j,k), ~] = find_reservation_wage(sol.Wm(:, n), U_val, gr.w);

                %% Female reservation wage: W_f(wR, aJ, am, af) = U(aJ, am, af)
                [wR_f(i,j,k), ~] = find_reservation_wage(sol.Wf(:, n), U_val, gr.w);
            end
        end
    end

    res.wR_m = wR_m;
    res.wR_f = wR_f;
end
