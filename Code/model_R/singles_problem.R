###############################################################################
# Singles' Problem — Continuous-Time Search Model with Savings
# Solves separately for male and female singles (gender-specific parameters)
# Numerical approach (from 882 notes):
#   - Discretize wage offers on [w_lb, w_ub] using truncated lognormal PMF (Module 1 Sec 2.2)
#   - Discretize asset grid on [0, a_max] (Module 2 Part 2)
#   - Upwind finite difference for U_a, E_a (Module 2 Sec 4a)
#   - Implicit method for value function iteration (Module 2 Sec 3b)
#   - Bisection for reservation wages (Module 1 Sec 5.1.1)
###############################################################################

library(Matrix)
library(ggplot2)

# ─── Common Parameters ───────────────────────────────────────────────────────
rho     <- 0.04 / 12       # monthly discount rate
sigma_u <- 1.5             # risk aversion (CRRA)
r       <- 0.02 / 12       # monthly risk-free rate

# Wage distribution — truncated lognormal (common across genders)
sigma_w <- 0.05
mu_w    <- -sigma_w^2 / 2

# Search cost: kappa(s) = kappa0 * s^kappa1
kappa0 <- 0.5
kappa1 <- 2.0

# Marriage shut off (eta = 0)
eta <- 0

# ─── Gender-Specific Parameters ──────────────────────────────────────────────
params <- list(
  m = list(
    label   = "Male",
    lambda  = 0.25,    # job offer rate, unemployed (monthly)
    gamma_e = 0.03,    # job offer rate, employed (monthly)
    delta   = 0.0054,  # job destruction rate (monthly)
    b       = 0.4      # unemployment benefit
  ),
  f = list(
    label   = "Female",
    lambda  = 0.22,
    gamma_e = 0.02,
    delta   = 0.0063,
    b       = 0.42
  )
)

# ─── Utility ─────────────────────────────────────────────────────────────────
u <- function(c) {
  if (sigma_u == 1) return(log(c))
  c^(1 - sigma_u) / (1 - sigma_u)
}
u_prime     <- function(c) c^(-sigma_u)
u_prime_inv <- function(v) v^(-1 / sigma_u)

kappa           <- function(s) kappa0 * s^kappa1
kappa_prime_inv <- function(v) (v / (kappa0 * kappa1))^(1 / (kappa1 - 1))

# ─── Grids ───────────────────────────────────────────────────────────────────
N_w  <- 200
w_lb <- exp(mu_w - 3 * sigma_w)
w_ub <- exp(mu_w + 3 * sigma_w)
w_grid <- seq(w_lb, w_ub, length.out = N_w)
dw <- w_grid[2] - w_grid[1]

# PMF for truncated lognormal (Module 1 Sec 2.2)
F_cdf <- function(w) plnorm(w, meanlog = mu_w, sdlog = sigma_w)
F_lb <- F_cdf(w_lb)
F_ub <- F_cdf(w_ub)

pmf_w <- numeric(N_w)
for (j in 1:N_w) {
  lo <- w_lb + (j - 1) * dw
  hi <- w_lb + j * dw
  pmf_w[j] <- (F_cdf(hi) - F_cdf(lo)) / (F_ub - F_lb)
}
pmf_w <- pmf_w / sum(pmf_w)

# Asset grid
N_a   <- 100
a_lb  <- 0
a_max <- 10
a_grid <- seq(a_lb, a_max, length.out = N_a)
da <- a_grid[2] - a_grid[1]

cat("Grid sizes: N_w =", N_w, ", N_a =", N_a, "\n")
cat("Wage support: [", round(w_lb, 4), ",", round(w_ub, 4), "]\n")
cat("Asset support: [", a_lb, ",", a_max, "]\n\n")

# ─── Solver Function ─────────────────────────────────────────────────────────
solve_singles <- function(par) {

  lambda_i  <- par$lambda
  gamma_i   <- par$gamma_e
  delta_i   <- par$delta
  b_i       <- par$b

  # Iteration parameters
  Delta   <- 100
  max_iter <- 3000
  tol     <- 1e-6
  damping <- 0.5

  # Initial guesses
  U <- numeric(N_a)
  E <- matrix(0, nrow = N_w, ncol = N_a)
  for (ia in 1:N_a) {
    U[ia] <- u(max(b_i + r * a_grid[ia], 1e-10)) / rho
    for (iw in 1:N_w) {
      E[iw, ia] <- u(max(w_grid[iw] + r * a_grid[ia], 1e-10)) / rho
    }
  }

  cat(sprintf("  Solving for %s singles...\n", par$label))

  for (iter in 1:max_iter) {

    # ── Upwind derivatives and consumption for U(a) ──
    dUf <- numeric(N_a)
    dUb <- numeric(N_a)
    dUf[1:(N_a-1)] <- (U[2:N_a] - U[1:(N_a-1)]) / da
    dUf[N_a] <- u_prime(b_i + r * a_grid[N_a])
    dUb[2:N_a] <- (U[2:N_a] - U[1:(N_a-1)]) / da
    dUb[1] <- u_prime(b_i + r * a_grid[1])

    cf <- u_prime_inv(pmax(dUf, 1e-10))
    cb <- u_prime_inv(pmax(dUb, 1e-10))
    sf_u <- b_i + r * a_grid - cf
    sb_u <- b_i + r * a_grid - cb

    c_U <- numeric(N_a)
    for (ia in 1:N_a) {
      if (sf_u[ia] > 0) {
        c_U[ia] <- cf[ia]
      } else if (sb_u[ia] < 0) {
        c_U[ia] <- cb[ia]
      } else {
        c_U[ia] <- b_i + r * a_grid[ia]
      }
    }

    # ── Semi-implicit option value for unemployed ──
    prob_accept <- numeric(N_a)
    E_accept    <- numeric(N_a)
    for (ia in 1:N_a) {
      accept <- E[, ia] > U[ia]
      prob_accept[ia] <- sum(pmf_w[accept])
      E_accept[ia]    <- sum(E[accept, ia] * pmf_w[accept])
    }

    # ── Build A matrix for U ──
    drift_U <- b_i + r * a_grid - c_U
    x_U <- -pmin(drift_U, 0) / da
    z_U <-  pmax(drift_U, 0) / da
    x_U[1] <- 0; z_U[N_a] <- 0
    y_U <- -(x_U + z_U)

    A_U <- bandSparse(N_a, N_a, k = c(-1, 0, 1),
                      diagonals = list(x_U[2:N_a], y_U, z_U[1:(N_a-1)]))

    B_U <- (1/Delta + rho) * Diagonal(N_a) - A_U +
           Diagonal(x = lambda_i * prob_accept)
    b_U <- sapply(c_U, function(cc) u(max(cc, 1e-10))) +
           lambda_i * E_accept + U / Delta

    U_new <- as.numeric(solve(B_U, b_U))

    # ── Solve for E(w, a) for each wage ──
    E_new <- matrix(0, nrow = N_w, ncol = N_a)

    for (iw in 1:N_w) {
      w_curr <- w_grid[iw]
      Ew <- E[iw, ]

      dEf <- numeric(N_a); dEb <- numeric(N_a)
      dEf[1:(N_a-1)] <- (Ew[2:N_a] - Ew[1:(N_a-1)]) / da
      dEf[N_a] <- u_prime(w_curr + r * a_grid[N_a])
      dEb[2:N_a] <- (Ew[2:N_a] - Ew[1:(N_a-1)]) / da
      dEb[1] <- u_prime(w_curr + r * a_grid[1])

      cf_e <- u_prime_inv(pmax(dEf, 1e-10))
      cb_e <- u_prime_inv(pmax(dEb, 1e-10))
      sf_e <- w_curr + r * a_grid - cf_e
      sb_e <- w_curr + r * a_grid - cb_e

      c_E <- numeric(N_a)
      for (ia in 1:N_a) {
        if (sf_e[ia] > 0) {
          c_E[ia] <- cf_e[ia]
        } else if (sb_e[ia] < 0) {
          c_E[ia] <- cb_e[ia]
        } else {
          c_E[ia] <- w_curr + r * a_grid[ia]
        }
      }

      # On-the-job search (semi-implicit)
      s_star      <- numeric(N_a)
      prob_better <- numeric(N_a)
      E_oj_accept <- numeric(N_a)
      for (ia in 1:N_a) {
        better <- (1:N_w >= iw) & (E[, ia] > E[iw, ia])
        gains_oj <- sum((E[better, ia] - E[iw, ia]) * pmf_w[better])
        prob_better[ia] <- sum(pmf_w[better])
        E_oj_accept[ia] <- sum(E[better, ia] * pmf_w[better])

        opt_val <- gamma_i * gains_oj
        if (opt_val > 0) {
          s_star[ia] <- kappa_prime_inv(opt_val)
        }
      }

      # Build A matrix for E
      drift_E <- w_curr + r * a_grid - c_E
      x_E <- -pmin(drift_E, 0) / da
      z_E <-  pmax(drift_E, 0) / da
      x_E[1] <- 0; z_E[N_a] <- 0
      y_E <- -(x_E + z_E)

      A_E <- bandSparse(N_a, N_a, k = c(-1, 0, 1),
                        diagonals = list(x_E[2:N_a], y_E, z_E[1:(N_a-1)]))

      B_E <- (1/Delta + rho + delta_i) * Diagonal(N_a) - A_E +
             Diagonal(x = s_star * gamma_i * prob_better)
      b_E <- sapply(c_E, function(cc) u(max(cc, 1e-10))) - kappa(s_star) +
             s_star * gamma_i * E_oj_accept + delta_i * U + Ew / Delta

      E_new[iw, ] <- as.numeric(solve(B_E, b_E))
    }

    # ── Damped update and convergence check ──
    diff_U <- max(abs(U_new - U))
    diff_E <- max(abs(E_new - E))
    dist <- max(diff_U, diff_E)

    U <- damping * U_new + (1 - damping) * U
    E <- damping * E_new + (1 - damping) * E

    if (iter %% 100 == 0 || iter == 1) {
      cat(sprintf("    Iter %4d | dist = %.2e\n", iter, dist))
    }
    if (dist < tol) {
      cat(sprintf("    Converged at iter %d | dist = %.2e\n", iter, dist))
      break
    }
  }

  # ── Reservation wages by bisection (Module 1 Sec 5.1.1) ──
  w_R <- numeric(N_a)
  for (ia in 1:N_a) {
    target <- U[ia]
    if (E[1, ia] >= target)   { w_R[ia] <- w_lb; next }
    if (E[N_w, ia] < target)  { w_R[ia] <- w_ub; next }

    lo <- 1; hi <- N_w
    for (bis in 1:100) {
      mid <- floor((lo + hi) / 2)
      if (mid == lo) break
      if (E[mid, ia] < target) lo <- mid else hi <- mid
    }
    E_lo <- E[lo, ia]; E_hi <- E[hi, ia]
    if (abs(E_hi - E_lo) > 1e-15) {
      frac <- (target - E_lo) / (E_hi - E_lo)
      w_R[ia] <- w_grid[lo] + frac * (w_grid[hi] - w_grid[lo])
    } else {
      w_R[ia] <- w_grid[lo]
    }
  }

  cat(sprintf("  %s reservation wage: [%.4f, %.4f]\n\n",
              par$label, min(w_R), max(w_R)))

  list(U = U, E = E, w_R = w_R)
}

# ─── Solve for Both Genders ──────────────────────────────────────────────────
results <- list()
for (g in names(params)) {
  results[[g]] <- solve_singles(params[[g]])
}

# ─── Plots ───────────────────────────────────────────────────────────────────

# --- Plot 1: Reservation wages for both genders ---
df_wR <- rbind(
  data.frame(a = a_grid, w_R = results$m$w_R, Gender = "Male"),
  data.frame(a = a_grid, w_R = results$f$w_R, Gender = "Female")
)

p1 <- ggplot(df_wR, aes(x = a, y = w_R, color = Gender)) +
  geom_line(linewidth = 1.2) +
  scale_color_manual(values = c("Male" = "steelblue", "Female" = "coral")) +
  labs(title = "Singles' Reservation Wages",
       x = "Assets (a)",
       y = "Reservation Wage") +
  theme_minimal(base_size = 14) 

print(p1)

# --- Plot 2: Value functions — combine both genders using facets ---
w_select_idx <- c(1, floor(N_w/4), floor(N_w/2), floor(3*N_w/4), N_w)
colors_e <- c("firebrick", "darkorange", "forestgreen", "dodgerblue", "purple")
w_labels <- sapply(w_select_idx, function(i) sprintf("E(w=%.3f)", w_grid[i]))

df_vf_all <- data.frame()
for (g in names(params)) {
  res <- results[[g]]
  # U(a)
  df_vf_all <- rbind(df_vf_all,
    data.frame(a = a_grid, value = res$U, curve = "U(a)",
               Gender = params[[g]]$label))
  # E(w,a) for selected wages
  for (k in seq_along(w_select_idx)) {
    iw <- w_select_idx[k]
    df_vf_all <- rbind(df_vf_all,
      data.frame(a = a_grid, value = res$E[iw, ], curve = w_labels[k],
                 Gender = params[[g]]$label))
  }
}

p2 <- ggplot(df_vf_all, aes(x = a, y = value, color = curve)) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~ Gender) +
  scale_color_manual(values = setNames(c("black", colors_e),
                                       c("U(a)", w_labels))) +
  labs(title = "Value Functions: U(a) and E(w, a)",
       x = "Assets (a)", y = "Value", color = "") +
  theme_minimal(base_size = 14)

print(p2)

# --- Plot 3: Optimal search effort for both genders ---
a_select_idx <- c(1, floor(N_a/2), N_a)

df_search_all <- data.frame()
for (g in names(params)) {
  res <- results[[g]]
  s_full <- matrix(0, nrow = N_w, ncol = N_a)
  for (iw in 1:N_w) {
    for (ia in 1:N_a) {
      better <- (1:N_w >= iw) & (res$E[, ia] > res$E[iw, ia])
      gains_oj <- sum((res$E[better, ia] - res$E[iw, ia]) * pmf_w[better])
      opt_val <- params[[g]]$gamma_e * gains_oj
      if (opt_val > 0) s_full[iw, ia] <- kappa_prime_inv(opt_val)
    }
  }

  df_tmp <- do.call(rbind, lapply(a_select_idx, function(ia) {
    data.frame(w = w_grid, s = s_full[, ia],
               a_level = sprintf("a = %.1f", a_grid[ia]),
               Gender = params[[g]]$label)
  }))
  df_search_all <- rbind(df_search_all, df_tmp)
}

p3 <- ggplot(df_search_all, aes(x = w, y = s, color = a_level, linetype = Gender)) +
  geom_line(linewidth = 0.9) +
  labs(title = "Optimal On-the-Job Search Effort",
       x = "Current Wage (w)", y = "Search Intensity (s)",
       color = "Asset Level", linetype = "Gender") +
  theme_minimal(base_size = 14)

print(p3)
