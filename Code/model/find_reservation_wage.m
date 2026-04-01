function [wR, status] = find_reservation_wage(W_vec, U_val, w_grid, tol)
% FIND_RESERVATION_WAGE  Find reservation wage via bracket + bisection.
%
%   [wR, status] = find_reservation_wage(W_vec, U_val, w_grid)
%   [wR, status] = find_reservation_wage(W_vec, U_val, w_grid, tol)
%
%   From model3.tex (lines 115-122), the reservation wage w^R satisfies:
%       W(w^R, state) = U(state)
%   For singles:  E_sin(w^R, a) = U_sin(a).
%   For couples:  W_m(w^R, a^J, a_m, a_f) = U(a^J, a_m, a_f).
%
%   No closed-form exists with savings. This function finds w^R by:
%     1. Bracketing: scan the wage grid to find adjacent points where
%        W crosses U (i.e., W_vec changes sign relative to U_val).
%     2. Bisection: refine the bracket to tolerance tol using linear
%        interpolation of W between grid points.
%
%   Inputs:
%     W_vec  : N_w x 1 — employed value function evaluated at each wage
%              grid point, for a fixed asset state. Should be increasing
%              in wage (higher wage => higher value).
%     U_val  : scalar — unemployed value at the same asset state.
%     w_grid : N_w x 1 — wage grid (ascending).
%     tol    : (optional) scalar — convergence tolerance for bisection.
%              Default: 1e-10.
%
%   Outputs:
%     wR     : scalar — reservation wage.
%     status : struct with fields:
%       .bracket_found : logical — true if a sign change was found on the
%                        wage grid.
%       .residual      : scalar — |W(wR) - U_val| after bisection.
%       .flag          : string — 'converged', 'accept_all', 'reject_all'.
%         'converged'  : bracket found, bisection converged within tol.
%         'accept_all' : W(w_min) >= U, so agent accepts any offer.
%         'reject_all' : W(w_max) < U, so agent rejects all offers.
%
%   Reference: compute_reservation_wages.m (existing linear-interpolation
%   approach), docs/solution_tasks.md (Task 1, Reservation wages section).
%
%   See also: compute_reservation_wages, solve_singles

    if nargin < 4
        tol = 1e-10;
    end

    N_w = length(w_grid);
    max_bisect = 100;  % max bisection iterations

    % Initialize status
    status.bracket_found = false;
    status.residual      = NaN;
    status.flag          = '';

    % Compute gap: G(w) = W(w) - U. Reservation wage is where G = 0.
    G = W_vec - U_val;

    %% --- Case 1: Agent accepts any offer (W(w_min) >= U) ---
    if G(1) >= 0
        wR = w_grid(1);
        status.bracket_found = true;
        status.residual      = abs(G(1));
        status.flag          = 'accept_all';
        return
    end

    %% --- Case 2: Agent rejects all offers (W(w_max) < U) ---
    if G(N_w) < 0
        wR = w_grid(N_w);
        status.bracket_found = false;
        status.residual      = abs(G(N_w));
        status.flag          = 'reject_all';
        return
    end

    %% --- Case 3: Bracket exists — find it ---
    idx_lo = 0;
    for iw = 1:(N_w - 1)
        if G(iw) < 0 && G(iw + 1) >= 0
            idx_lo = iw;
            break
        end
    end

    if idx_lo == 0
        % Should not happen given Cases 1-2, but handle gracefully.
        % W may be non-monotone; fall back to first crossing.
        for iw = 1:(N_w - 1)
            if sign(G(iw)) ~= sign(G(iw + 1))
                idx_lo = iw;
                break
            end
        end
    end

    if idx_lo == 0
        % Truly no bracket found (pathological case)
        wR = w_grid(N_w);
        status.bracket_found = false;
        status.residual      = abs(G(N_w));
        status.flag          = 'reject_all';
        return
    end

    status.bracket_found = true;

    %% --- Bisection within the bracket ---
    w_lo = w_grid(idx_lo);
    w_hi = w_grid(idx_lo + 1);
    G_lo = G(idx_lo);
    G_hi = G(idx_lo + 1);

    % Linear interpolation values at the two grid points for bisection.
    % We interpolate W linearly between grid points to evaluate G at
    % arbitrary w in [w_lo, w_hi].
    W_lo = W_vec(idx_lo);
    W_hi = W_vec(idx_lo + 1);

    for iter = 1:max_bisect
        % Bisect
        w_mid = (w_lo + w_hi) / 2;

        % Linear interpolation of W at w_mid
        frac   = (w_mid - w_grid(idx_lo)) / (w_grid(idx_lo + 1) - w_grid(idx_lo));
        W_mid  = W_lo + frac * (W_hi - W_lo);
        G_mid  = W_mid - U_val;

        if abs(G_mid) < tol
            break
        end

        if G_mid < 0
            w_lo = w_mid;
            G_lo = G_mid;
        else
            w_hi = w_mid;
            G_hi = G_mid;
        end
    end

    wR = w_mid;
    status.residual = abs(G_mid);
    status.flag     = 'converged';

end
