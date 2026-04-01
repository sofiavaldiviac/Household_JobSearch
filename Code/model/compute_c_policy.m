function c_star = compute_c_policy(Va, par)
% COMPUTE_C_POLICY  Optimal consumption from FOC inversion (CRRA utility).
%
%   c_star = compute_c_policy(Va, par)
%
%   From model3.tex (lines 96-103), the FOC for consumption is:
%       u'(c*) = V_a
%   For CRRA utility u(c) = c^(1-sigma)/(1-sigma), inversion gives:
%       c* = V_a^(-1/sigma)
%
%   This applies in every state: couples (derivative w.r.t. joint account
%   a^J) and singles (derivative w.r.t. individual account a).
%
%   Inputs:
%     Va  : array of any size — marginal value of assets (V_a > 0 required)
%     par : parameter struct from set_parameters.m (needs field: sigma)
%
%   Output:
%     c_star : array same size as Va — optimal consumption, strictly > 0
%
%   Reference: Achdou et al. (2022), FOC for consumption in continuous-time
%   heterogeneous-agent models.
%
%   See also: build_A_1d (inline c* computation), set_parameters

    % Enforce positivity of Va to avoid complex/negative consumption
    Va_safe = max(Va, 1e-12);

    % FOC inversion: c* = Va^(-1/sigma)
    c_star = Va_safe .^ (-1 / par.sigma);

end
