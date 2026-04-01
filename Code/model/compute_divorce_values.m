function [Vd_m, Vd_f] = compute_divorce_values(sol_m, sol_f, theta, par, gr)
% COMPUTE_DIVORCE_VALUES  Map singles values onto the 3D couples grid.
%
%   [Vd_m, Vd_f] = compute_divorce_values(sol_m, sol_f, theta, par, gr)
%
%   For each point (aJ_i, am_j, af_k) on the couples grid, compute the
%   post-divorce asset level(s) and interpolate the singles unemployed
%   value function.
%
%   theta : 'O' (universal community) or 'L' (limited community)
%
%   Returns:
%     Vd_m : N_aJ x N_am x N_af  divorce value for male
%     Vd_f : N_aJ x N_am x N_af  divorce value for female

    N_aJ = gr.N_aJ;
    N_am = gr.N_am;
    N_af = gr.N_af;

    Vd_m = zeros(N_aJ, N_am, N_af);
    Vd_f = zeros(N_aJ, N_am, N_af);

    for i = 1:N_aJ
        for j = 1:N_am
            for k = 1:N_af
                aJ = gr.aJ(i);
                am = gr.am(j);
                af = gr.af(k);

                if theta == 'O'
                    % Universal community: all assets pooled, split equally
                    a_total = aJ + am + af;
                    a_m_div = 0.5 * (1 - par.tau_O) * a_total;
                    a_f_div = 0.5 * (1 - par.tau_O) * a_total;
                else  % theta == 'L'
                    % Limited community: joint split, individual kept
                    a_m_div = 0.5 * aJ + am;
                    a_f_div = 0.5 * aJ + af;
                end

                % Interpolate U_sin on the singles asset grid
                Vd_m(i,j,k) = interp1(gr.a_sin, sol_m.U_sin, a_m_div, ...
                               'linear', 'extrap');
                Vd_f(i,j,k) = interp1(gr.a_sin, sol_f.U_sin, a_f_div, ...
                               'linear', 'extrap');
            end
        end
    end

end
