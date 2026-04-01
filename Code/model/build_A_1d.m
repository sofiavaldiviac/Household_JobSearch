function [A, c_opt] = build_A_1d(V, a_grid, income, par)
% BUILD_A_1D  Sparse 1D upwind drift matrix for asset savings.
%
%   [A, c_opt] = build_A_1d(V, a_grid, income, par)
%
%   V       : N x 1 value function on the asset grid
%   a_grid  : N x 1 asset grid
%   income  : N x 1 flow income at each grid point (before consumption)
%   par     : parameter struct (needs r, u1inv, sigma)
%
%   Returns:
%     A     : N x N sparse matrix (drift operator)
%     c_opt : N x 1 optimal consumption

    N  = length(a_grid);
    da = diff(a_grid);   % (N-1) x 1

    %% ----- Finite differences of V -----
    dVf = zeros(N,1);   % forward difference
    dVb = zeros(N,1);   % backward difference

    dVf(1:N-1) = (V(2:N) - V(1:N-1)) ./ da;
    dVb(2:N)   = (V(2:N) - V(1:N-1)) ./ da;

    % Boundary: at a_max, use backward; at a_min, ensure agent saves
    dVf(N)   = par.u1(income(N));   % c = income at upper bound (state constraint)
    dVb(1)   = par.u1(income(1));   % c = income at lower bound

    %% ----- Optimal consumption from FOC: u'(c) = V_a -----
    cf = par.u1inv(dVf);   % consumption if forward diff used
    cb = par.u1inv(dVb);   % consumption if backward diff used

    %% ----- Drift (savings rate) -----
    sf = income - cf;      % drift under forward diff
    sb = income - cb;      % drift under backward diff

    %% ----- Upwind scheme -----
    % Use forward when saving (s > 0), backward when dissaving (s < 0)
    If = sf > 0;
    Ib = sb < 0;
    I0 = ~If & ~Ib;       % at steady state: use c = income

    % Optimal consumption
    c_opt = cf .* If + cb .* Ib + income .* I0;

    % Upwind derivatives
    dV_upwind = dVf .* If + dVb .* Ib + par.u1(income) .* I0;

    %% ----- Build sparse tridiagonal matrix -----
    % A(i,i-1) = -sb(i)/da(i-1)   (backward, negative drift)
    % A(i,i)   = sf(i)/da(i) + sb(i)/da(i-1)  (both with sign)
    % A(i,i+1) = sf(i)/da(i)      (forward, positive drift)

    X = -min(sb,0) ./ [da(1); da];        % lower diagonal coefficients
    Z =  max(sf,0) ./ [da; da(end)];      % upper diagonal coefficients
    Y = -X - Z;                            % main diagonal (row sums = 0)

    % Fix boundaries
    X(1) = 0;
    Z(N) = 0;

    A = spdiags([X Y Z], [-1 0 1], N, N);

end
