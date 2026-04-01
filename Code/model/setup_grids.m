function gr = setup_grids(par)
% SETUP_GRIDS  Build asset and wage grids plus quadrature weights.
%
%   gr = setup_grids(par)

    %% --- Singles asset grid (power-spaced, denser near constraint) ---
    gr.a_sin = power_spaced_grid(par.a_sin_min, par.a_sin_max, par.N_a_sin, 1);
    gr.da_sin = diff(gr.a_sin);  % spacings (N-1 x 1)

    %% --- Joint asset grid ---
    gr.aJ = power_spaced_grid(par.aJ_min, par.aJ_max, par.N_aJ, 1);
    gr.daJ = diff(gr.aJ);

    %% --- Individual asset grids (uniform for now) ---
    gr.am = linspace(par.am_min, par.am_max, par.N_am)';
    gr.dam = diff(gr.am);

    gr.af = linspace(par.af_min, par.af_max, par.N_af)';
    gr.daf = diff(gr.af);

    %% --- Wage grid (equally spaced on [w_min, w_max]) ---
    gr.w = linspace(par.w_min, par.w_max, par.N_w)';
    gr.dw = diff(gr.w);

    %% --- Wage distribution: truncated log-normal ---
    % PDF and CDF evaluated at grid points
    gr.F_w = (logncdf(gr.w, par.mu_w, par.sig_w) - logncdf(par.w_min, par.mu_w, par.sig_w)) ...
           / (logncdf(par.w_max, par.mu_w, par.sig_w) - logncdf(par.w_min, par.mu_w, par.sig_w));
    gr.f_w = lognpdf(gr.w, par.mu_w, par.sig_w) ...
           / (logncdf(par.w_max, par.mu_w, par.sig_w) - logncdf(par.w_min, par.mu_w, par.sig_w));

    %% --- Quadrature weights for wage integration (trapezoidal) ---
    gr.qw = trapz_weights(gr.w);

    %% --- Store sizes for convenience ---
    gr.N_a_sin = par.N_a_sin;
    gr.N_aJ    = par.N_aJ;
    gr.N_am    = par.N_am;
    gr.N_af    = par.N_af;
    gr.N_w     = par.N_w;
    gr.N3      = par.N_aJ * par.N_am * par.N_af;  % 3D couple grid size

end

%% ===== Helper functions =====

function x = power_spaced_grid(x_min, x_max, N, power)
% Power-spaced grid: denser near x_min.
    z = linspace(0, 1, N)';
    x = x_min + (x_max - x_min) * z.^power;
end

function w = trapz_weights(x)
% Trapezoidal quadrature weights for a vector x.
    N = length(x);
    w = zeros(N,1);
    w(1)     = (x(2) - x(1)) / 2;
    w(N)     = (x(N) - x(N-1)) / 2;
    w(2:N-1) = (x(3:N) - x(1:N-2)) / 2;
end
