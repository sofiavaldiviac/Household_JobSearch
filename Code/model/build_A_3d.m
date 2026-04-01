function [A, c_opt] = build_A_3d(V, income, par, gr)
% BUILD_A_3D  Sparse 3D upwind drift matrix for couples on (aJ, am, af).
%
%   [A, c_opt] = build_A_3d(V, income, par, gr)
%
%   V      : N3 x 1 value function (lexicographic order: aJ fastest, then am, then af)
%   income : N3 x 1 flow income at each grid point (r*a_total + wage_income)
%   par    : parameter struct
%   gr     : grid struct
%
%   The ordering convention: index = i + (j-1)*N_aJ + (k-1)*N_aJ*N_am
%     where i indexes aJ, j indexes am, k indexes af.
%
%   Drift directions:
%     aJ : endogenous saving, upwind based on sign of (income - c)
%     am : drift = r * am >= 0, always forward-differenced
%     af : drift = r * af >= 0, always forward-differenced
%
%   Returns:
%     A     : N3 x N3 sparse matrix
%     c_opt : N3 x 1 optimal consumption

    N_aJ = gr.N_aJ;
    N_am = gr.N_am;
    N_af = gr.N_af;
    N3   = N_aJ * N_am * N_af;

    % Precompute grid spacings
    daJ = gr.daJ;  % (N_aJ-1) x 1
    dam = gr.dam;  % (N_am-1) x 1
    daf = gr.daf;  % (N_af-1) x 1

    % Build 3D index arrays
    [ii, jj, kk] = ndgrid(1:N_aJ, 1:N_am, 1:N_af);
    ii = ii(:); jj = jj(:); kk = kk(:);

    % Linear index function
    lin = @(i,j,k) i + (j-1)*N_aJ + (k-1)*N_aJ*N_am;

    %% ----- Forward and backward differences in aJ -----
    dVf_aJ = zeros(N3,1);
    dVb_aJ = zeros(N3,1);

    for n = 1:N3
        i = ii(n); j = jj(n); k = kk(n);
        if i < N_aJ
            dVf_aJ(n) = (V(lin(i+1,j,k)) - V(n)) / daJ(i);
        end
        if i > 1
            dVb_aJ(n) = (V(n) - V(lin(i-1,j,k))) / daJ(i-1);
        end
    end

    % Boundary conditions for aJ
    for n = 1:N3
        i = ii(n);
        if i == N_aJ
            dVf_aJ(n) = par.u1(income(n));  % c = income at upper bound
        end
        if i == 1
            dVb_aJ(n) = par.u1(income(n));  % c = income at lower bound
        end
    end

    %% ----- Consumption and saving (upwind on aJ) -----
    cf = par.u1inv(dVf_aJ);
    cb = par.u1inv(dVb_aJ);

    sf = income - cf;   % savings rate forward
    sb = income - cb;   % savings rate backward

    If = sf > 0;
    Ib = (sb < 0) & ~If;
    I0 = ~If & ~Ib;

    c_opt = cf .* If + cb .* Ib + income .* I0;

    %% ----- Forward differences in am and af (deterministic drift r*a >= 0) -----
    drift_am = zeros(N3,1);
    drift_af = zeros(N3,1);
    dVf_am   = zeros(N3,1);
    dVf_af   = zeros(N3,1);

    for n = 1:N3
        i = ii(n); j = jj(n); k = kk(n);

        % am drift: r * am(j)
        drift_am(n) = par.r * gr.am(j);
        if j < N_am
            dVf_am(n) = (V(lin(i,j+1,k)) - V(n)) / dam(j);
        end
        % at boundary j == N_am, drift goes to zero (absorbing) or we set dV = 0

        % af drift: r * af(k)
        drift_af(n) = par.r * gr.af(k);
        if k < N_af
            dVf_af(n) = (V(lin(i,j,k+1)) - V(n)) / daf(k);
        end
    end

    %% ----- Assemble sparse matrix -----
    % We'll collect (row, col, val) triplets
    max_nnz = 7 * N3;
    rows = zeros(max_nnz, 1);
    cols = zeros(max_nnz, 1);
    vals = zeros(max_nnz, 1);
    cnt  = 0;

    for n = 1:N3
        i = ii(n); j = jj(n); k = kk(n);
        diag_val = 0;

        % --- aJ dimension (upwind) ---
        if If(n) && i < N_aJ
            % Forward: positive drift
            rate = max(sf(n),0) / daJ(i);
            cnt = cnt + 1; rows(cnt) = n; cols(cnt) = lin(i+1,j,k); vals(cnt) = rate;
            diag_val = diag_val - rate;
        end
        if Ib(n) && i > 1
            % Backward: negative drift
            rate = -min(sb(n),0) / daJ(i-1);
            cnt = cnt + 1; rows(cnt) = n; cols(cnt) = lin(i-1,j,k); vals(cnt) = rate;
            diag_val = diag_val - rate;
        end

        % --- am dimension (forward only, drift >= 0) ---
        if j < N_am && drift_am(n) > 0
            rate = drift_am(n) / dam(j);
            cnt = cnt + 1; rows(cnt) = n; cols(cnt) = lin(i,j+1,k); vals(cnt) = rate;
            diag_val = diag_val - rate;
        end

        % --- af dimension (forward only, drift >= 0) ---
        if k < N_af && drift_af(n) > 0
            rate = drift_af(n) / daf(k);
            cnt = cnt + 1; rows(cnt) = n; cols(cnt) = lin(i,j,k+1); vals(cnt) = rate;
            diag_val = diag_val - rate;
        end

        % --- Diagonal entry ---
        cnt = cnt + 1; rows(cnt) = n; cols(cnt) = n; vals(cnt) = diag_val;
    end

    % Trim and build sparse matrix
    rows = rows(1:cnt);
    cols = cols(1:cnt);
    vals = vals(1:cnt);

    A = sparse(rows, cols, vals, N3, N3);

end
