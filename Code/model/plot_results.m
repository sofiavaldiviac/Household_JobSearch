function plot_results(res_O, res_L, sol_m, sol_f, sol_O, sol_L, par, gr)
% PLOT_RESULTS  Generate figures comparing property regimes.
%
%   res_O, res_L : reservation wage structs (theta=O, theta=L)
%   sol_m, sol_f : singles solutions
%   sol_O, sol_L : couples solutions
%   par, gr      : parameters and grids

    %% ===== Figure 1: Singles reservation wages =====
    figure('Name', 'Singles Reservation Wages');
    plot(gr.a_sin, sol_m.wR_sin, 'b-', 'LineWidth', 2); hold on;
    plot(gr.a_sin, sol_f.wR_sin, 'r--', 'LineWidth', 2);
    xlabel('Assets (a)'); ylabel('Reservation Wage');
    title('Singles Reservation Wages');
    legend('Male', 'Female', 'Location', 'best');
    grid on;

    %% ===== Figure 2: Couples reservation wages — male, at median am, af =====
    j_med = round(gr.N_am / 2);
    k_med = round(gr.N_af / 2);

    wR_m_O = res_O.wR_m(:, j_med, k_med);
    wR_m_L = res_L.wR_m(:, j_med, k_med);

    figure('Name', 'Male Reservation Wages by Regime');
    plot(gr.aJ, wR_m_O, 'b-', 'LineWidth', 2); hold on;
    plot(gr.aJ, wR_m_L, 'r--', 'LineWidth', 2);
    xlabel('Joint Assets (a^J)'); ylabel('Reservation Wage');
    title(sprintf('Male Reservation Wage (a_m=%.1f, a_f=%.1f)', ...
        gr.am(j_med), gr.af(k_med)));
    legend('\theta = O (Universal)', '\theta = L (Limited)', 'Location', 'best');
    grid on;

    %% ===== Figure 3: Couples reservation wages — female =====
    wR_f_O = res_O.wR_f(:, j_med, k_med);
    wR_f_L = res_L.wR_f(:, j_med, k_med);

    figure('Name', 'Female Reservation Wages by Regime');
    plot(gr.aJ, wR_f_O, 'b-', 'LineWidth', 2); hold on;
    plot(gr.aJ, wR_f_L, 'r--', 'LineWidth', 2);
    xlabel('Joint Assets (a^J)'); ylabel('Reservation Wage');
    title(sprintf('Female Reservation Wage (a_m=%.1f, a_f=%.1f)', ...
        gr.am(j_med), gr.af(k_med)));
    legend('\theta = O (Universal)', '\theta = L (Limited)', 'Location', 'best');
    grid on;

    %% ===== Figure 4: Difference in reservation wages (O - L) =====
    diff_m = res_O.wR_m(:, j_med, k_med) - res_L.wR_m(:, j_med, k_med);
    diff_f = res_O.wR_f(:, j_med, k_med) - res_L.wR_f(:, j_med, k_med);

    figure('Name', 'Reservation Wage Difference (Universal - Limited)');
    plot(gr.aJ, diff_m, 'b-', 'LineWidth', 2); hold on;
    plot(gr.aJ, diff_f, 'r--', 'LineWidth', 2);
    xlabel('Joint Assets (a^J)'); ylabel('w^R(O) - w^R(L)');
    title('Reservation Wage Difference: Universal minus Limited');
    legend('Male', 'Female', 'Location', 'best');
    yline(0, 'k:', 'LineWidth', 1);
    grid on;

    %% ===== Figure 5: Value functions (UU) along aJ =====
    figure('Name', 'Dual-Unemployed Value Functions');
    UU_O = reshape(sol_O.UU, [gr.N_aJ, gr.N_am, gr.N_af]);
    UU_L = reshape(sol_L.UU, [gr.N_aJ, gr.N_am, gr.N_af]);
    plot(gr.aJ, UU_O(:, j_med, k_med), 'b-', 'LineWidth', 2); hold on;
    plot(gr.aJ, UU_L(:, j_med, k_med), 'r--', 'LineWidth', 2);
    xlabel('Joint Assets (a^J)'); ylabel('U(a^J, a_m, a_f)');
    title('Dual-Unemployed Value Function');
    legend('\theta = O', '\theta = L', 'Location', 'best');
    grid on;

    %% ===== Figure 6: Reservation wages as function of individual assets =====
    i_med_aJ = round(gr.N_aJ / 2);  % fix aJ at median

    figure('Name', 'Reservation Wages vs Individual Assets');
    subplot(1,2,1);
    wR_m_am_O = squeeze(res_O.wR_m(i_med_aJ, :, k_med));
    wR_m_am_L = squeeze(res_L.wR_m(i_med_aJ, :, k_med));
    plot(gr.am, wR_m_am_O, 'b-', 'LineWidth', 2); hold on;
    plot(gr.am, wR_m_am_L, 'r--', 'LineWidth', 2);
    xlabel('Male Individual Assets (a_m)'); ylabel('Male w^R');
    title(sprintf('a^J=%.1f, a_f=%.1f', gr.aJ(i_med_aJ), gr.af(k_med)));
    legend('\theta=O', '\theta=L', 'Location', 'best');
    grid on;

    subplot(1,2,2);
    wR_f_af_O = squeeze(res_O.wR_f(i_med_aJ, j_med, :));
    wR_f_af_L = squeeze(res_L.wR_f(i_med_aJ, j_med, :));
    plot(gr.af, wR_f_af_O, 'b-', 'LineWidth', 2); hold on;
    plot(gr.af, wR_f_af_L, 'r--', 'LineWidth', 2);
    xlabel('Female Individual Assets (a_f)'); ylabel('Female w^R');
    title(sprintf('a^J=%.1f, a_m=%.1f', gr.aJ(i_med_aJ), gr.am(j_med)));
    legend('\theta=O', '\theta=L', 'Location', 'best');
    grid on;

    fprintf('Figures generated.\n');
end
