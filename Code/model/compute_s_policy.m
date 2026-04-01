function s_star = compute_s_policy(V_current, V_all, gamma_i, par, gr)
% COMPUTE_S_POLICY  Optimal on-the-job search intensity from FOC.
%
%   s_star = compute_s_policy(V_current, V_all, gamma_i, par, gr)
%
%   From model3.tex (lines 105-113), the FOC for OTJ search intensity is:
%       kappa'(s*) = gamma_i * integral_{w}^{w_bar} [V(w') - V(w)] dF(w')
%   With kappa(s) = kappa0 * s^kappa1, inversion gives:
%       s* = (gamma_i / (kappa0 * kappa1) * integral)^(1/(kappa1-1))
%
%   The integral sums over wages w' > w where V(w') > V(w), weighted by
%   the wage density f(w') and trapezoidal quadrature weights.
%
%   Inputs:
%     V_current : N_a x 1 — value function at current wage w for each
%                 asset grid point (for singles: E_sin(iw,:)'; for couples:
%                 analogous slice of Wm or EE)
%     V_all     : N_w x N_a — value function at ALL wages for each asset
%                 grid point (rows = wages, cols = assets)
%     gamma_i   : scalar — OTJ offer arrival rate for this agent
%     par       : parameter struct (needs: kappa0, kappa1)
%     gr        : grid struct (needs: w, f_w, qw, N_w)
%
%   Output:
%     s_star : N_a x 1 — optimal search intensity (>= 0) at each asset
%              grid point. Returns 0 where the gain integral is zero or
%              negative (no improving offers available).
%
%   The current wage index is inferred by matching V_current against V_all.
%   If V_current does not exactly match a row of V_all, the integral is
%   computed over ALL wages where V(w') > V(w) (this handles the couples
%   case where the "current" slice may not correspond to a single row).
%
%   Reference: solve_single_hjb.m (inline s* computation, lines 37-47).
%
%   See also: solve_single_hjb, set_parameters, setup_grids

    N_a = size(V_current, 1);
    N_w = gr.N_w;

    % Identify which wage index corresponds to V_current (if any)
    iw_current = 0;
    for iw = 1:N_w
        if max(abs(V_all(iw,:)' - V_current)) < 1e-14
            iw_current = iw;
            break
        end
    end

    % Compute integral: sum over w' > w of max{V(w') - V(w), 0} * f(w') * qw(w')
    OTJ_gain = zeros(N_a, 1);

    if iw_current > 0
        % Exact match: only sum over wages strictly above current
        for jw = (iw_current + 1):N_w
            OTJ_gain = OTJ_gain + max(V_all(jw,:)' - V_current, 0) ...
                       .* gr.f_w(jw) .* gr.qw(jw);
        end
    else
        % No exact match: sum over all wages where V(w') > V(w)
        for jw = 1:N_w
            OTJ_gain = OTJ_gain + max(V_all(jw,:)' - V_current, 0) ...
                       .* gr.f_w(jw) .* gr.qw(jw);
        end
    end

    % FOC inversion: s* = (gamma / (kappa0 * kappa1) * integral)^(1/(kappa1-1))
    raw = gamma_i * OTJ_gain / (par.kappa0 * par.kappa1);

    % Exponent: 1/(kappa1 - 1). For kappa1 = 2, this is 1.
    exponent = 1 / (par.kappa1 - 1);

    s_star = real(raw .^ exponent);
    s_star = max(s_star, 0);   % enforce non-negativity

end
