function par = set_parameters()
% SET_PARAMETERS  Return struct with all model parameters.
%
%   par = set_parameters()

    %% Preferences
    par.rho   = 0.05;       % discount rate
    par.sigma = 2.0;        % CRRA coefficient

    %% Interest rate
    par.r = 0.03;

    %% Labour market — male
    par.b_m      = 0.4;     % unemployment benefit
    par.lambda_m = 0.5;     % job offer arrival rate (unemployed)
    par.gamma_m  = 0.1;     % job offer arrival rate (employed, OTJ)
    par.delta_m  = 0.05;    % job destruction rate

    %% Labour market — female
    par.b_f      = 0.4;
    par.lambda_f = 0.5;
    par.gamma_f  = 0.1;
    par.delta_f  = 0.05;

    %% Search cost: kappa(s) = kappa0 * s^kappa1
    par.kappa0 = 0.5;
    par.kappa1 = 2.0;       % quadratic search cost

    %% Wage distribution (log-normal)
    par.w_min  = 0.2;
    par.w_max  = 3.0;
    par.mu_w   = 0.0;       % mean of log wage
    par.sig_w  = 0.5;       % std  of log wage

    %% Divorce
    par.pi_div = 0.02;      % divorce arrival rate
    par.tau_O  = 0.10;      % dissolution cost, universal community property
    par.tau_L  = 0.00;      % dissolution cost, limited community property

    %% Marriage (set to 0 for first pass)
    par.eta = 0.0;          % marriage arrival rate
    par.chi = 0.5;          % prob partner is employed at marriage

    %% Wealth shocks (set to 0 for first pass)
    par.mu_shock_m = 0.0;   % wealth shock arrival rate, male
    par.mu_shock_f = 0.0;   % wealth shock arrival rate, female

    %% Numerical parameters
    par.Delta_t   = 0.1;    % implicit time step (small for stability)
    par.max_iter  = 500;    % max HJB iterations (inner)
    par.tol_hjb   = 1e-8;   % convergence tolerance (inner)
    par.max_outer = 500;    % max outer iterations
    par.tol_outer = 5e-1;   % convergence tolerance (outer)
    par.damp      = 0.5;    % damping weight on old value (if needed)

    %% Grid sizes
    par.N_a_sin = 100;      % singles asset grid
    par.N_aJ    = 50;       % joint asset grid (couples)
    par.N_am    = 15;       % male individual asset grid
    par.N_af    = 15;       % female individual asset grid
    par.N_w     = 15;       % wage grid

    %% Grid ranges
    par.a_sin_min = -1;     par.a_sin_max = 30;
    par.aJ_min    = -1;     par.aJ_max    = 30;
    par.am_min    =  0;     par.am_max    = 15;
    par.af_min    =  0;     par.af_max    = 15;

    %% Utility function (CRRA)
    par.u  = @(c) (max(c,1e-12).^(1-par.sigma) - 1) ./ (1-par.sigma);
    par.u1 = @(c) c.^(-par.sigma);                          % u'(c)
    par.u1inv = @(Vp) max(Vp, 1e-12).^(-1/par.sigma);      % (u')^{-1}

end
