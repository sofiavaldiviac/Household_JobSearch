###############################################################################
# Couples' Problem — Universal Community Property (theta = U)
#
# Divorce: each spouse gets a_i^D = (1-tau_O)/2 * a, then reverts to singles.
# Requires: singles' solution (run singles_problem.R first and save results).
#
# Numerical approach (882 notes):
#   - Implicit method with upwind finite differences (Module 2)
#   - Semi-implicit treatment of option values
#   - Bisection for reservation wages (Module 1)
###############################################################################

library(Matrix)
library(ggplot2)

# ─── Run singles' problem first to get divorce values ────────────────────────
cat("Step 0: Solving singles' problem for divorce values...\n")
source("singles_problem.R")
singles_results <- results  # save {m, f} each with $U, $E, $w_R

# ─── Additional Couple Parameters ────────────────────────────────────────────
pi_div  <- 0.02 / 12       # monthly divorce rate
tau_O   <- 0.10             # dissolution cost (universal community)
mu_shock <- 0.05 / 12       # monthly wealth shock arrival rate (per spouse)
sigma_z <- 1.0              # wealth shock scale
mu_z    <- -sigma_z^2 / 2 + log(5)  # wealth shock location

# ─── Reduced Grids for Couples ───────────────────────────────────────────────
N_w_c  <- 50    # wage grid points (reduced from 200)
N_a_c  <- 50    # asset grid points (reduced from 100)

w_grid_c <- seq(w_lb, w_ub, length.out = N_w_c)
dw_c <- w_grid_c[2] - w_grid_c[1]

a_grid_c <- seq(a_lb, a_max, length.out = N_a_c)
da_c <- a_grid_c[2] - a_grid_c[1]

# PMF on the reduced wage grid
pmf_w_c <- numeric(N_w_c)
for (j in 1:N_w_c) {
  lo <- w_lb + (j - 1) * dw_c
  hi <- w_lb + j * dw_c
  pmf_w_c[j] <- (F_cdf(hi) - F_cdf(lo)) / (F_ub - F_lb)
}
pmf_w_c <- pmf_w_c / sum(pmf_w_c)

# Wealth shock grid (truncated lognormal)
N_z <- 20
z_ub <- exp(mu_z + 3 * sigma_z)
z_lb_val <- max(exp(mu_z - 3 * sigma_z), 1e-6)
z_grid <- seq(z_lb_val, z_ub, length.out = N_z)
dz <- z_grid[2] - z_grid[1]

F_z_cdf <- function(z) plnorm(z, meanlog = mu_z, sdlog = sigma_z)
F_z_lb <- F_z_cdf(z_lb_val)
F_z_ub <- F_z_cdf(z_ub)

pmf_z <- numeric(N_z)
for (j in 1:N_z) {
  lo <- z_lb_val + (j - 1) * dz
  hi <- z_lb_val + j * dz
  pmf_z[j] <- (F_z_cdf(hi) - F_z_cdf(lo)) / (F_z_ub - F_z_lb)
}
pmf_z <- pmf_z / sum(pmf_z)

cat(sprintf("Couples grids: N_w = %d, N_a = %d, N_z = %d\n", N_w_c, N_a_c, N_z))
cat(sprintf("State sizes: U = %d, W = %d, E = %d\n",
            N_a_c, N_w_c * N_a_c, N_w_c^2 * N_a_c))

# ─── Divorce Values (interpolated from singles' solution) ────────────────────
# Under universal community: a_i^D = (1 - tau_O) / 2 * a
# V_i^D(a) = U_i^sin(a_i^D) if unemployed at time of divorce
# For employed spouse: V_i^D(a) = E_i^sin(w_i, a_i^D)
# We'll use the unemployed value as the divorce outside option
# (conservative; could also check if currently employed)

interp_single <- function(V_single, a_grid_single, a_query) {
  # Linear interpolation of V_single(a) onto a_query points
  approx(a_grid_single, V_single, xout = a_query, rule = 2)$y
}

# Divorce value for each spouse as a function of couple's total assets
V_D_m <- numeric(N_a_c)  # V_m^D(a)
V_D_f <- numeric(N_a_c)  # V_f^D(a)
for (ia in 1:N_a_c) {
  a_div <- (1 - tau_O) / 2 * a_grid_c[ia]
  V_D_m[ia] <- interp_single(singles_results$m$U, a_grid, a_div)
  V_D_f[ia] <- interp_single(singles_results$f$U, a_grid, a_div)
}

cat("Divorce values computed.\n")

# ─── Helper: Wealth shock expected value ─────────────────────────────────────
# For a value function V(a), compute E[V(a + z)] where z ~ G(z)
# Uses linear interpolation of V onto shifted grid points
wealth_shock_EV <- function(V_a, a_grid_local, ia, pmf_z_local, z_grid_local) {
  ev <- 0
  a_curr <- a_grid_local[ia]
  for (iz in 1:length(z_grid_local)) {
    a_new <- min(a_curr + z_grid_local[iz], max(a_grid_local))
    v_new <- approx(a_grid_local, V_a, xout = a_new, rule = 2)$y
    ev <- ev + v_new * pmf_z_local[iz]
  }
  ev
}

# Vectorized version: for all asset grid points
wealth_shock_EV_all <- function(V_a, a_grid_local) {
  ev <- numeric(length(a_grid_local))
  for (ia in 1:length(a_grid_local)) {
    ev[ia] <- wealth_shock_EV(V_a, a_grid_local, ia, pmf_z, z_grid)
  }
  ev
}

# ─── Helper: Upwind scheme + A matrix construction ──────────────────────────
build_upwind <- function(V_a, income, a_grid_local, da_local) {
  N <- length(a_grid_local)

  # Forward and backward derivatives
  dVf <- numeric(N); dVb <- numeric(N)
  dVf[1:(N-1)] <- (V_a[2:N] - V_a[1:(N-1)]) / da_local
  dVf[N] <- u_prime(income[N])
  dVb[2:N] <- (V_a[2:N] - V_a[1:(N-1)]) / da_local
  dVb[1] <- u_prime(income[1])

  cf <- u_prime_inv(pmax(dVf, 1e-10))
  cb <- u_prime_inv(pmax(dVb, 1e-10))
  sf <- income - cf
  sb <- income - cb

  cons <- numeric(N)
  for (i in 1:N) {
    if (sf[i] > 0) {
      cons[i] <- cf[i]
    } else if (sb[i] < 0) {
      cons[i] <- cb[i]
    } else {
      cons[i] <- income[i]
    }
  }

  drift <- income - cons
  x <- -pmin(drift, 0) / da_local
  z <- pmax(drift, 0) / da_local
  x[1] <- 0; z[N] <- 0
  y <- -(x + z)

  A <- bandSparse(N, N, k = c(-1, 0, 1),
                  diagonals = list(x[2:N], y, z[1:(N-1)]))

  list(cons = cons, drift = drift, A = A)
}

# ─── Initialize Value Functions ──────────────────────────────────────────────
cat("\nInitializing couple value functions...\n")

b_m <- params$m$b
b_f <- params$f$b
lambda_m <- params$m$lambda
lambda_f <- params$f$lambda
gamma_m  <- params$m$gamma_e
gamma_f  <- params$f$gamma_e
delta_m  <- params$m$delta
delta_f  <- params$f$delta

# U(a): dual-unemployed
Uc <- numeric(N_a_c)
for (ia in 1:N_a_c) {
  Uc[ia] <- u(max(b_m + b_f + r * a_grid_c[ia], 1e-10)) / rho
}

# W_m(w_m, a): male employed, female unemployed — N_w_c x N_a_c
Wm <- matrix(0, nrow = N_w_c, ncol = N_a_c)
for (iw in 1:N_w_c) {
  for (ia in 1:N_a_c) {
    Wm[iw, ia] <- u(max(w_grid_c[iw] + b_f + r * a_grid_c[ia], 1e-10)) / rho
  }
}

# W_f(w_f, a): female employed, male unemployed
Wf <- matrix(0, nrow = N_w_c, ncol = N_a_c)
for (iw in 1:N_w_c) {
  for (ia in 1:N_a_c) {
    Wf[iw, ia] <- u(max(b_m + w_grid_c[iw] + r * a_grid_c[ia], 1e-10)) / rho
  }
}

# E(w_m, w_f, a): dual-employed — N_w_c x N_w_c x N_a_c
Ec <- array(0, dim = c(N_w_c, N_w_c, N_a_c))
for (iwm in 1:N_w_c) {
  for (iwf in 1:N_w_c) {
    for (ia in 1:N_a_c) {
      Ec[iwm, iwf, ia] <- u(max(w_grid_c[iwm] + w_grid_c[iwf] +
                                r * a_grid_c[ia], 1e-10)) / rho
    }
  }
}

# ─── Iteration Parameters ───────────────────────────────────────────────────
Delta_c   <- 100
max_iter_c <- 500
tol_c     <- 1e-5
damping_c <- 0.5

cat(sprintf("Starting couples VFI (max %d iters, tol = %.1e)...\n\n",
            max_iter_c, tol_c))

# ─── Main Iteration Loop ────────────────────────────────────────────────────
for (iter in 1:max_iter_c) {

  # ════════════════════════════════════════════════════════════════════════
  # (A) Update U(a) — Dual-Unemployed
  # ════════════════════════════════════════════════════════════════════════
  income_U <- b_m + b_f + r * a_grid_c
  uw <- build_upwind(Uc, income_U, a_grid_c, da_c)

  # Option value: male gets offer
  prob_acc_m_U <- numeric(N_a_c)
  Wm_acc_U     <- numeric(N_a_c)
  for (ia in 1:N_a_c) {
    accept <- Wm[, ia] > Uc[ia]
    prob_acc_m_U[ia] <- sum(pmf_w_c[accept])
    Wm_acc_U[ia]     <- sum(Wm[accept, ia] * pmf_w_c[accept])
  }

  # Option value: female gets offer
  prob_acc_f_U <- numeric(N_a_c)
  Wf_acc_U     <- numeric(N_a_c)
  for (ia in 1:N_a_c) {
    accept <- Wf[, ia] > Uc[ia]
    prob_acc_f_U[ia] <- sum(pmf_w_c[accept])
    Wf_acc_U[ia]     <- sum(Wf[accept, ia] * pmf_w_c[accept])
  }

  # Wealth shocks
  ws_m_U <- wealth_shock_EV_all(Uc, a_grid_c)
  ws_f_U <- wealth_shock_EV_all(Uc, a_grid_c)

  # Divorce
  divorce_val_U <- V_D_m + V_D_f

  # Build system
  diag_extra <- lambda_m * prob_acc_m_U + lambda_f * prob_acc_f_U +
                mu_shock + mu_shock + pi_div
  B_Uc <- (1/Delta_c + rho) * Diagonal(N_a_c) - uw$A +
          Diagonal(x = diag_extra)
  b_Uc <- sapply(uw$cons, function(cc) u(max(cc, 1e-10))) +
          lambda_m * Wm_acc_U + lambda_f * Wf_acc_U +
          mu_shock * ws_m_U + mu_shock * ws_f_U +
          pi_div * divorce_val_U +
          Uc / Delta_c

  Uc_new <- as.numeric(solve(B_Uc, b_Uc))

  # ════════════════════════════════════════════════════════════════════════
  # (B) Update W_m(w_m, a) — Male employed, female unemployed
  # ════════════════════════════════════════════════════════════════════════
  Wm_new <- matrix(0, nrow = N_w_c, ncol = N_a_c)

  for (iwm in 1:N_w_c) {
    wm_curr <- w_grid_c[iwm]
    Wm_curr <- Wm[iwm, ]
    income_Wm <- wm_curr + b_f + r * a_grid_c

    uw_wm <- build_upwind(Wm_curr, income_Wm, a_grid_c, da_c)

    # Male on-the-job search (semi-implicit)
    s_m <- numeric(N_a_c)
    prob_better_m <- numeric(N_a_c)
    Wm_oj_acc    <- numeric(N_a_c)
    for (ia in 1:N_a_c) {
      better <- (1:N_w_c >= iwm) & (Wm[, ia] > Wm[iwm, ia])
      gains <- sum((Wm[better, ia] - Wm[iwm, ia]) * pmf_w_c[better])
      prob_better_m[ia] <- sum(pmf_w_c[better])
      Wm_oj_acc[ia]     <- sum(Wm[better, ia] * pmf_w_c[better])
      opt_val <- gamma_m * gains
      if (opt_val > 0) s_m[ia] <- kappa_prime_inv(opt_val)
    }

    # Female gets offer: max{E(wm, wf, a), W_f(wf, a), W_m(wm, a)}
    # Breadwinner cycle: she accepts and he may quit, or both work, or reject
    prob_f_offer <- numeric(N_a_c)
    EV_f_offer   <- numeric(N_a_c)
    for (ia in 1:N_a_c) {
      ev_offer <- 0
      pr_offer <- 0
      for (jwf in 1:N_w_c) {
        # Best option if female gets wage w_grid_c[jwf]
        val_both <- Ec[iwm, jwf, ia]         # both work
        val_she  <- Wf[jwf, ia]              # she works, he quits
        val_stay <- Wm[iwm, ia]              # reject her offer
        best <- max(val_both, val_she, val_stay)
        if (best > Wm[iwm, ia]) {
          pr_offer <- pr_offer + pmf_w_c[jwf]
          ev_offer <- ev_offer + best * pmf_w_c[jwf]
        }
      }
      prob_f_offer[ia] <- pr_offer
      EV_f_offer[ia]   <- ev_offer
    }

    # Wealth shocks
    ws_m_Wm <- wealth_shock_EV_all(Wm_curr, a_grid_c)
    ws_f_Wm <- wealth_shock_EV_all(Wm_curr, a_grid_c)

    # Build system
    diag_Wm <- delta_m + s_m * gamma_m * prob_better_m +
               lambda_f * prob_f_offer +
               mu_shock + mu_shock + pi_div
    B_Wm <- (1/Delta_c + rho) * Diagonal(N_a_c) - uw_wm$A +
            Diagonal(x = diag_Wm)
    b_Wm <- sapply(uw_wm$cons, function(cc) u(max(cc, 1e-10))) -
            kappa(s_m) +
            delta_m * Uc +
            s_m * gamma_m * Wm_oj_acc +
            lambda_f * EV_f_offer +
            mu_shock * ws_m_Wm + mu_shock * ws_f_Wm +
            pi_div * divorce_val_U +
            Wm_curr / Delta_c

    Wm_new[iwm, ] <- as.numeric(solve(B_Wm, b_Wm))
  }

  # ════════════════════════════════════════════════════════════════════════
  # (C) Update W_f(w_f, a) — Female employed, male unemployed
  # ════════════════════════════════════════════════════════════════════════
  Wf_new <- matrix(0, nrow = N_w_c, ncol = N_a_c)

  for (iwf in 1:N_w_c) {
    wf_curr <- w_grid_c[iwf]
    Wf_curr <- Wf[iwf, ]
    income_Wf <- b_m + wf_curr + r * a_grid_c

    uw_wf <- build_upwind(Wf_curr, income_Wf, a_grid_c, da_c)

    # Female on-the-job search (semi-implicit)
    s_f <- numeric(N_a_c)
    prob_better_f <- numeric(N_a_c)
    Wf_oj_acc    <- numeric(N_a_c)
    for (ia in 1:N_a_c) {
      better <- (1:N_w_c >= iwf) & (Wf[, ia] > Wf[iwf, ia])
      gains <- sum((Wf[better, ia] - Wf[iwf, ia]) * pmf_w_c[better])
      prob_better_f[ia] <- sum(pmf_w_c[better])
      Wf_oj_acc[ia]     <- sum(Wf[better, ia] * pmf_w_c[better])
      opt_val <- gamma_f * gains
      if (opt_val > 0) s_f[ia] <- kappa_prime_inv(opt_val)
    }

    # Male gets offer: max{E(wm, wf, a), W_m(wm, a), W_f(wf, a)}
    prob_m_offer <- numeric(N_a_c)
    EV_m_offer   <- numeric(N_a_c)
    for (ia in 1:N_a_c) {
      ev_offer <- 0
      pr_offer <- 0
      for (jwm in 1:N_w_c) {
        val_both <- Ec[jwm, iwf, ia]
        val_he   <- Wm[jwm, ia]
        val_stay <- Wf[iwf, ia]
        best <- max(val_both, val_he, val_stay)
        if (best > Wf[iwf, ia]) {
          pr_offer <- pr_offer + pmf_w_c[jwm]
          ev_offer <- ev_offer + best * pmf_w_c[jwm]
        }
      }
      prob_m_offer[ia] <- pr_offer
      EV_m_offer[ia]   <- ev_offer
    }

    # Wealth shocks
    ws_m_Wf <- wealth_shock_EV_all(Wf_curr, a_grid_c)
    ws_f_Wf <- wealth_shock_EV_all(Wf_curr, a_grid_c)

    # Build system
    diag_Wf <- delta_f + s_f * gamma_f * prob_better_f +
               lambda_m * prob_m_offer +
               mu_shock + mu_shock + pi_div
    B_Wf <- (1/Delta_c + rho) * Diagonal(N_a_c) - uw_wf$A +
            Diagonal(x = diag_Wf)
    b_Wf <- sapply(uw_wf$cons, function(cc) u(max(cc, 1e-10))) -
            kappa(s_f) +
            delta_f * Uc +
            s_f * gamma_f * Wf_oj_acc +
            lambda_m * EV_m_offer +
            mu_shock * ws_m_Wf + mu_shock * ws_f_Wf +
            pi_div * divorce_val_U +
            Wf_curr / Delta_c

    Wf_new[iwf, ] <- as.numeric(solve(B_Wf, b_Wf))
  }

  # ════════════════════════════════════════════════════════════════════════
  # (D) Update E(w_m, w_f, a) — Dual-Employed
  # ════════════════════════════════════════════════════════════════════════
  Ec_new <- array(0, dim = c(N_w_c, N_w_c, N_a_c))

  for (iwm in 1:N_w_c) {
    for (iwf in 1:N_w_c) {
      wm_curr <- w_grid_c[iwm]
      wf_curr <- w_grid_c[iwf]
      Ec_curr <- Ec[iwm, iwf, ]
      income_E <- wm_curr + wf_curr + r * a_grid_c

      uw_E <- build_upwind(Ec_curr, income_E, a_grid_c, da_c)

      # Male on-the-job search: max{E(w', wf, a), W_m(w', a), E(wm, wf, a)}
      s_m_E <- numeric(N_a_c)
      prob_m_oj <- numeric(N_a_c)
      EV_m_oj   <- numeric(N_a_c)
      for (ia in 1:N_a_c) {
        pr <- 0; ev <- 0
        gains_for_foc <- 0
        for (jwm in iwm:N_w_c) {
          val_both <- Ec[jwm, iwf, ia]
          val_he   <- Wm[jwm, ia]   # he switches, she quits? No: W_m = he works, she doesn't
          best <- max(val_both, val_he)
          gain <- best - Ec[iwm, iwf, ia]
          if (gain > 0) {
            pr <- pr + pmf_w_c[jwm]
            ev <- ev + best * pmf_w_c[jwm]
            gains_for_foc <- gains_for_foc + gain * pmf_w_c[jwm]
          }
        }
        prob_m_oj[ia] <- pr
        EV_m_oj[ia]   <- ev
        opt_val <- gamma_m * gains_for_foc
        if (opt_val > 0) s_m_E[ia] <- kappa_prime_inv(opt_val)
      }

      # Female on-the-job search: max{E(wm, w', a), W_f(w', a), E(wm, wf, a)}
      s_f_E <- numeric(N_a_c)
      prob_f_oj <- numeric(N_a_c)
      EV_f_oj   <- numeric(N_a_c)
      for (ia in 1:N_a_c) {
        pr <- 0; ev <- 0
        gains_for_foc <- 0
        for (jwf in iwf:N_w_c) {
          val_both <- Ec[iwm, jwf, ia]
          val_she  <- Wf[jwf, ia]
          best <- max(val_both, val_she)
          gain <- best - Ec[iwm, iwf, ia]
          if (gain > 0) {
            pr <- pr + pmf_w_c[jwf]
            ev <- ev + best * pmf_w_c[jwf]
            gains_for_foc <- gains_for_foc + gain * pmf_w_c[jwf]
          }
        }
        prob_f_oj[ia] <- pr
        EV_f_oj[ia]   <- ev
        opt_val <- gamma_f * gains_for_foc
        if (opt_val > 0) s_f_E[ia] <- kappa_prime_inv(opt_val)
      }

      # Wealth shocks
      ws_m_E <- wealth_shock_EV_all(Ec_curr, a_grid_c)
      ws_f_E <- wealth_shock_EV_all(Ec_curr, a_grid_c)

      # Build system
      diag_E <- delta_m + delta_f +
                s_m_E * gamma_m * prob_m_oj +
                s_f_E * gamma_f * prob_f_oj +
                mu_shock + mu_shock + pi_div
      B_Ec <- (1/Delta_c + rho) * Diagonal(N_a_c) - uw_E$A +
              Diagonal(x = diag_E)
      b_Ec <- sapply(uw_E$cons, function(cc) u(max(cc, 1e-10))) -
              kappa(s_m_E) - kappa(s_f_E) +
              delta_m * Wf[iwf, ] +    # male loses job → W_f state
              delta_f * Wm[iwm, ] +    # female loses job → W_m state
              s_m_E * gamma_m * EV_m_oj +
              s_f_E * gamma_f * EV_f_oj +
              mu_shock * ws_m_E + mu_shock * ws_f_E +
              pi_div * divorce_val_U +
              Ec_curr / Delta_c

      Ec_new[iwm, iwf, ] <- as.numeric(solve(B_Ec, b_Ec))
    }
  }

  # ════════════════════════════════════════════════════════════════════════
  # Damped update and convergence
  # ════════════════════════════════════════════════════════════════════════
  dist_U <- max(abs(Uc_new - Uc))
  dist_Wm <- max(abs(Wm_new - Wm))
  dist_Wf <- max(abs(Wf_new - Wf))
  dist_E <- max(abs(Ec_new - Ec))
  dist <- max(dist_U, dist_Wm, dist_Wf, dist_E)

  Uc <- damping_c * Uc_new + (1 - damping_c) * Uc
  Wm <- damping_c * Wm_new + (1 - damping_c) * Wm
  Wf <- damping_c * Wf_new + (1 - damping_c) * Wf
  Ec <- damping_c * Ec_new + (1 - damping_c) * Ec

  cat(sprintf("  Iter %3d | dist: U=%.2e Wm=%.2e Wf=%.2e E=%.2e | max=%.2e\n",
              iter, dist_U, dist_Wm, dist_Wf, dist_E, dist))

  if (dist < tol_c) {
    cat(sprintf("  Converged at iter %d\n", iter))
    break
  }
}

# ─── Reservation Wages ───────────────────────────────────────────────────────
cat("\nComputing couples' reservation wages...\n")

# Dual-unemployed reservation wages: w_R_m(a) s.t. W_m(w_R, a) = U(a)
wR_m_couple <- numeric(N_a_c)
wR_f_couple <- numeric(N_a_c)

for (ia in 1:N_a_c) {
  # Male reservation wage
  target <- Uc[ia]
  if (Wm[1, ia] >= target) { wR_m_couple[ia] <- w_grid_c[1]; next }
  if (Wm[N_w_c, ia] < target) { wR_m_couple[ia] <- w_grid_c[N_w_c]; next }
  lo <- 1; hi <- N_w_c
  for (bis in 1:100) {
    mid <- floor((lo + hi) / 2)
    if (mid == lo) break
    if (Wm[mid, ia] < target) lo <- mid else hi <- mid
  }
  E_lo <- Wm[lo, ia]; E_hi <- Wm[hi, ia]
  if (abs(E_hi - E_lo) > 1e-15) {
    frac <- (target - E_lo) / (E_hi - E_lo)
    wR_m_couple[ia] <- w_grid_c[lo] + frac * (w_grid_c[hi] - w_grid_c[lo])
  } else {
    wR_m_couple[ia] <- w_grid_c[lo]
  }
}

for (ia in 1:N_a_c) {
  # Female reservation wage
  target <- Uc[ia]
  if (Wf[1, ia] >= target) { wR_f_couple[ia] <- w_grid_c[1]; next }
  if (Wf[N_w_c, ia] < target) { wR_f_couple[ia] <- w_grid_c[N_w_c]; next }
  lo <- 1; hi <- N_w_c
  for (bis in 1:100) {
    mid <- floor((lo + hi) / 2)
    if (mid == lo) break
    if (Wf[mid, ia] < target) lo <- mid else hi <- mid
  }
  E_lo <- Wf[lo, ia]; E_hi <- Wf[hi, ia]
  if (abs(E_hi - E_lo) > 1e-15) {
    frac <- (target - E_lo) / (E_hi - E_lo)
    wR_f_couple[ia] <- w_grid_c[lo] + frac * (w_grid_c[hi] - w_grid_c[lo])
  } else {
    wR_f_couple[ia] <- w_grid_c[lo]
  }
}

cat(sprintf("  Male couple w_R:   [%.4f, %.4f]\n", min(wR_m_couple), max(wR_m_couple)))
cat(sprintf("  Female couple w_R: [%.4f, %.4f]\n", min(wR_f_couple), max(wR_f_couple)))

# ─── Plots ───────────────────────────────────────────────────────────────────

# Interpolate singles' reservation wages onto the couple grid
wR_m_single_interp <- approx(a_grid, singles_results$m$w_R,
                              xout = a_grid_c, rule = 2)$y
wR_f_single_interp <- approx(a_grid, singles_results$f$w_R,
                              xout = a_grid_c, rule = 2)$y

# Plot: Reservation wages — singles vs couples
df_wR_all <- rbind(
  data.frame(a = a_grid_c, w_R = wR_m_couple, Gender = "Male", Status = "Couple"),
  data.frame(a = a_grid_c, w_R = wR_f_couple, Gender = "Female", Status = "Couple"),
  data.frame(a = a_grid_c, w_R = wR_m_single_interp, Gender = "Male", Status = "Single"),
  data.frame(a = a_grid_c, w_R = wR_f_single_interp, Gender = "Female", Status = "Single")
)

p_wR <- ggplot(df_wR_all, aes(x = a, y = w_R, color = Gender, linetype = Status)) +
  geom_line(linewidth = 1.1) +
  scale_color_manual(values = c("Male" = "steelblue", "Female" = "coral")) +
  scale_linetype_manual(values = c("Single" = "dashed", "Couple" = "solid")) +
  labs(title = "Reservation Wages: Singles vs Couples (Universal Community)",
       x = "Assets (a)", y = "Reservation Wage") +
  theme_minimal(base_size = 14)

print(p_wR)

# Plot: Couple value functions U(a), W_m(w, a), W_f(w, a) for median wage
w_med_idx <- floor(N_w_c / 2)

df_couple_vf <- rbind(
  data.frame(a = a_grid_c, value = Uc, curve = "U(a)"),
  data.frame(a = a_grid_c, value = Wm[w_med_idx, ],
             curve = sprintf("W_m(w=%.3f, a)", w_grid_c[w_med_idx])),
  data.frame(a = a_grid_c, value = Wf[w_med_idx, ],
             curve = sprintf("W_f(w=%.3f, a)", w_grid_c[w_med_idx])),
  data.frame(a = a_grid_c, value = Ec[w_med_idx, w_med_idx, ],
             curve = sprintf("E(%.3f, %.3f, a)", w_grid_c[w_med_idx], w_grid_c[w_med_idx]))
)

p_vf <- ggplot(df_couple_vf, aes(x = a, y = value, color = curve)) +
  geom_line(linewidth = 1) +
  labs(title = "Couple Value Functions (Universal Community)",
       x = "Assets (a)", y = "Value", color = "") +
  theme_minimal(base_size = 14)

print(p_vf)

