# Solving the Household Job Search Model: Task List

## Task 1: Analytical Policy Functions

From the FOCs in the HJBs, derive closed-form expressions for the policy functions.

### Consumption policy (all states)

The envelope condition gives:

$$c^* = (u')^{-1}(V_a)$$

where $V_a$ is the marginal value of the relevant asset (joint account for couples, $a$ for singles). For CRRA utility $u(c) = c^{1-\sigma}/(1-\sigma)$:

$$c^* = V_a^{-1/\sigma}$$

### On-the-job search intensity

From $\kappa'(s^*) = \gamma_i \int_{w}^{\bar{w}} [V(w') - V(w)] \, dF_i(w')$, with $\kappa(s) = \kappa_0 s^{\kappa_1}$:

$$s_i^* = \left(\frac{\gamma_i}{\kappa_0 \kappa_1} \int_w^{\bar{w}_i} [V(w') - V(w)] \, dF_i(w')\right)^{1/(\kappa_1 - 1)}$$

### Reservation wages

The reservation wage $w^R$ solves the indifference condition. For example, the dual-unemployed male reservation wage satisfies:

$$W_m(w^R_m, a^J, a_m, a_f; \theta) = U(a^J, a_m, a_f; \theta)$$

**No closed-form in general with savings.** The reservation wage is an implicit function of the full asset state. It must be computed numerically by interpolation on the value function grid:

- At each asset grid point, find $w^R$ such that $W_m(w^R, \cdot) - U(\cdot) = 0$.
- This is a root-finding problem on the wage grid (bisection or interpolation).

The reference file `solvewres_riskneut.m` does exactly this for the risk-neutral case using Chebyshev quadrature.

### Acceptance sets

The sets $\mathcal{A}^{EE}$ and $\mathcal{BW}$ are similarly implicit. At each state, compare:

$$E(w_m, w_f, \cdot) \quad \text{vs} \quad W_m(w_m, \cdot) \quad \text{vs} \quad W_f(w_f, \cdot)$$

to determine which option dominates. Computed by evaluation on the grid.

### Bottom line

Consumption and search effort have analytical expressions given value function derivatives. Reservation wages and acceptance sets are **numerical** — found by root-finding/comparison on the discretized value functions.

---

## Task 2: Kolmogorov Forward Equations (KFEs)

### How to Derive a KFE: Step-by-Step Guide

The KFE (also called the Fokker-Planck equation) describes how the distribution of agents across states evolves over time. In steady state, the distribution is constant, so the KFE says: **the net change in the mass of agents at any point in the state space is zero.**

We derive it by tracking two fundamentally different types of movement:

#### Type 1: Continuous drift (savings, job-ladder climbing)

Agents don't jump — they slide continuously through the state space. An agent saving at rate $\dot{a} > 0$ moves smoothly rightward along the asset axis.

**Where the divergence term comes from.** Consider a small interval $[a, a + da]$. The mass in this interval is $g(a) \, da$. Mass changes because agents flow in through the left boundary and out through the right boundary:

- Flow in through $a$: agents just below $a$ with positive drift push mass into the interval. The flow rate is $\dot{a}(a) \cdot g(a)$ (drift times density = probability current).
- Flow out through $a + da$: similarly, $\dot{a}(a+da) \cdot g(a+da)$.

The net change in mass is:

$$\frac{\partial g}{\partial t} \, da = \dot{a}(a) \cdot g(a) - \dot{a}(a+da) \cdot g(a+da) = -\frac{\partial[\dot{a} \cdot g]}{\partial a} \, da$$

This gives the **divergence term**: $-\partial_a[\dot{a} \cdot g]$.

**Intuition:** this is a conservation law. Think of water flowing through a pipe — if more water flows out of a section than flows in, the water level drops. The divergence operator measures exactly this net outflow of the probability current.

**In our model, divergence terms appear for:**

| Continuous state variable | Drift $\dot{x}$ | Divergence term in KFE |
|---|---|---|
| Joint assets $a^J$ | $ra^J + y - c^*$ (savings) | $-\partial_{a^J}[(ra^J + y - c^*) \cdot h]$ |
| Individual assets $a_i$ | $ra_i$ (interest only) | $-r \, \partial_{a_i}[a_i \cdot h]$ |
| Wage $w_m$ (on-the-job search) | $s_m^* \gamma_m f_m(w_m)[1-F_m(w_m)]$ | $-\partial_{w_m}[s_m^* \gamma_m f_m(w_m)(1-F_m(w_m)) \cdot h]$ |

The wage drift deserves explanation: on-the-job search creates a flow of agents from lower to higher wages. An employed agent at wage $w$ accepts any offer $w' > w$, so the effective "velocity" at which agents climb the wage ladder is $s^* \gamma \cdot [1 - F(w)]$ (search intensity times offer rate times probability the offer beats current wage), weighted by the offer density $f(w)$.

#### Type 2: Discrete jumps (Poisson events)

These are instantaneous transitions: job finding, job destruction, divorce, marriage, wealth shocks. Each Poisson event moves an agent from one state to another in an instant.

**General pattern.** For a Poisson event at rate $\alpha$ that moves agents from state $X$ to state $Y$:

- **Outflow from $X$:** $-\alpha \cdot g_X$ (agents leave $X$ at rate $\alpha$ per unit mass)
- **Inflow to $Y$:** $+\alpha \cdot g_X$ (those same agents arrive at $Y$)

**Each Poisson channel in our model:**

| Event | Rate | Who moves | From → To |
|---|---|---|---|
| Job finding (unemployed m) | $\lambda_m$ | UU couple draws wage $w$ from $F_m$ | If $w \geq w^R_m$: UU → Wm at wage $w$ |
| Job destruction (employed m) | $\delta_m$ | Wm couple | Wm → UU |
| OTJ offer (employed m) | $s_m^* \gamma_m$ | Wm couple draws $w'$ from $F_m$ | If $w' > w_m$: Wm at $w_m$ → Wm at $w'$ |
| f finds job in Wm state | $\lambda_f$ | Wm couple draws $w_f$ from $F_f$ | If $w_f \in \mathcal{A}_f^{EE}$: Wm → EE |
| | | | If $w_f \in \mathcal{BW}$: Wm → Wf (breadwinner) |
| Divorce | $\pi$ | Any couple | Couple → two singles at $a^D_i(\theta)$ |
| Marriage | $\eta$ | Two singles meet | Singles → couple at $a^J = 0$ |
| Wealth shock to $i$ | $\mu_i$ | Anyone | $a_i \mapsto a_i + z$, $z \sim G_i$ |

**Wealth shocks require special treatment.** A wealth shock doesn't just add/remove mass — it shifts agents along the $a_i$ axis. The density at $a_i$ loses mass (agents jump away at rate $\mu_i$) and gains mass from agents at $a_i - z$ who received shock $z$:

$$\text{Net wealth-shock effect} = -\mu_i \cdot g(a_i) + \mu_i \int_0^{\min(a_i, \bar{z}_i)} g(a_i - z) \, dG_i(z)$$

The first term is outflow (everyone at $a_i$ might get a shock). The second is inflow (agents at $a_i - z$ who got shock $z$ land at $a_i$).

#### Putting it together: recipe for any KFE

For any state with density $g$:

$$0 = \underbrace{-\partial_x[\dot{x} \cdot g]}_{\text{divergence (continuous drift)}} \underbrace{- \sum_k \alpha_k \cdot g}_{\text{Poisson outflows}} + \underbrace{\sum_k \text{(inflow terms from other states)}}_{\text{Poisson inflows}}$$

where the sum is over all Poisson channels $k$ with rates $\alpha_k$. Each inflow term matches an outflow from some other state's KFE — mass is conserved.

#### Worked example: unemployed single $g_i^U(a)$

Start with density $g_i^U(a)$ and ask: what happens to agents at asset level $a$?

**Step 1 — Continuous drift.** Assets evolve as $\dot{a} = ra + b_i - c^*(a)$. Agents slide along the $a$-axis:

$$-\partial_a\bigl[(ra + b_i - c^*) \cdot g_i^U\bigr]$$

**Step 2 — List all Poisson outflows.** Agents leave this state when:

1. They find a job: rate $\lambda_i$, but only offers above $w^R$ are accepted, so effective rate $= \lambda_i(1 - F_i(w^R_i(a)))$
2. They get married: rate $\eta$
3. They receive a wealth shock: rate $\mu_i$ (they jump to a different $a$)

Total outflow rate: $-[\lambda_i(1-F_i(w^R_i)) + \eta + \mu_i] \cdot g_i^U(a)$

**Step 3 — List all Poisson inflows.** Agents arrive at $(U, a)$ when:

1. An employed single at wage $w$ and asset $a$ loses their job: $+\delta_i \int g_i^E(w, a) \, dw$
2. A married person with $l_i = 0$ gets divorced and lands at asset $a$: $+\pi \cdot \mathcal{D}_i^{U \leftarrow \text{div}}(a)$
3. Someone at asset $a - z$ receives wealth shock $z$ and lands at $a$: $+\mu_i \int_0^{\min(a,\bar{z}_i)} g_i^U(a-z) \, dG_i(z)$

**Step 4 — Set the sum to zero (steady state):**

$$0 = -\partial_a[(ra + b_i - c^*) \, g_i^U] - [\lambda_i(1-F_i(w^R_i)) + \eta + \mu_i] \, g_i^U$$
$$\quad + \delta_i \int g_i^E(w,a) \, dw + \pi \cdot \mathcal{D}_i^{U \leftarrow \text{div}}(a) + \mu_i \int_0^{\min(a,\bar{z}_i)} g_i^U(a-z) \, dG_i(z)$$

That's the KFE. Every other KFE in the model follows the same recipe.

---

### Why the KFE is the Adjoint of the HJB Operator

There is a deep connection: the KFE operator is the **adjoint** (transpose) of the HJB operator. This is why, computationally, once you build the matrix $A$ for the HJB (from the upwind scheme in Tasks 3-4), the KFE matrix is simply $A^\top$:

- **HJB:** $(\rho I - A) V = u$ (value function satisfies this)
- **KFE:** $A^\top g = 0$ (stationary distribution satisfies this)

This is not a coincidence — it follows from integration by parts. The drift term $\dot{a} \cdot V'(a)$ in the HJB becomes $-\partial_a[\dot{a} \cdot g(a)]$ in the KFE, which is exactly the adjoint operation. So you only build one matrix $A$ and use it (transposed) for both problems.

---

### All KFEs with Detailed Term-by-Term Explanation

For each state, enumerate every flow channel. The KFEs characterize the stationary distributions.

### Coupled States

#### Dual-Unemployed $h_\theta^{UU}(a^J, a_m, a_f)$

**Outflows:**

| Channel | Rate | Destination |
|---------|------|-------------|
| m finds job | $\lambda_m(1 - F_m(w^R_m))$ | $h^{Wm}$ |
| f finds job | $\lambda_f(1 - F_f(w^R_f))$ | $h^{Wf}$ |
| Divorce | $\pi$ | $g_m^U, g_f^U$ (singles) |
| Wealth shock m | $\mu_m$ | Reshuffled within $h^{UU}$ |
| Wealth shock f | $\mu_f$ | Reshuffled within $h^{UU}$ |

**Inflows:**

| Channel | Source | Expression |
|---------|--------|------------|
| m's job destroyed | $h^{Wm}$ | $\delta_m \int h_\theta^{Wm}(w_m, a^J, a_m, a_f) \, dw_m$ |
| f's job destroyed | $h^{Wf}$ | $\delta_f \int h_\theta^{Wf}(w_f, a^J, a_m, a_f) \, dw_f$ |
| Wealth shock m | $h^{UU}$ | $\mu_m \int_0^{\min(a_m, \bar{z}_m)} h^{UU}(a^J, a_m - z, a_f) \, dG_m(z)$ |
| Wealth shock f | $h^{UU}$ | $\mu_f \int_0^{\min(a_f, \bar{z}_f)} h^{UU}(a^J, a_m, a_f - z) \, dG_f(z)$ |
| Marriage | Singles | $\eta \, g_m^U(a_m) \cdot \eta \, g_f^U(a_f) \cdot \mathbf{1}\{a^J = 0\}$ |

**Full KFE:**

$$0 = -\partial_{a^J}[\Phi^{a^J}_{UU} \cdot h^{UU}] - r \, \partial_{a_m}[a_m \, h^{UU}] - r \, \partial_{a_f}[a_f \, h^{UU}]$$
$$\quad - [\lambda_m(1 - F_m(w^R_m)) + \lambda_f(1 - F_f(w^R_f)) + \mu_m + \mu_f + \pi] \, h^{UU}$$
$$\quad + \text{[wealth shock inflows]} + \text{[job destruction inflows]} + \text{[marriage inflow]}$$

where drift $\Phi^{a^J}_{UU} = r a^J + b_m + b_f - c$.

---

#### Worker-Searcher $h_\theta^{Wm}(w_m, a^J, a_m, a_f)$ (m employed, f unemployed)

**Outflows:**

| Channel | Rate | Destination |
|---------|------|-------------|
| m's job destroyed | $\delta_m$ | $h^{UU}$ |
| m climbs job ladder | $s_m^* \gamma_m [1 - F_m(w_m)]$ | Upward drift in $w_m$ within $h^{Wm}$ |
| f finds job | $\lambda_f(1 - F_f(w^R_f))$ | $h^{EE}$ |
| Divorce | $\pi$ | Singles |
| Wealth shocks | $\mu_m, \mu_f$ | Reshuffled within $h^{Wm}$ |

**Inflows:**

| Channel | Source | Expression |
|---------|--------|------------|
| m accepted from UU | $h^{UU}$ | $\lambda_m f_m(w_m) \, \mathbf{1}\{w_m \geq w^R_m\} \cdot h^{UU}(a^J, a_m, a_f)$ |
| f's job destroyed in EE | $h^{EE}$ | $\delta_f \int h^{EE}(w_m, w_f, a^J, a_m, a_f) \, dw_f$ |
| Breadwinner from Wf | $h^{Wf}$ | $\lambda_m f_m(w_m) \int \mathbf{1}\{w_m \in \mathcal{BW}_m(w_f, \cdot)\} \cdot h^{Wf}(w_f, \cdot) \, dw_f$ |
| Marriage | Singles | At $a^J = 0$, m employed at $w_m$, f unemployed |
| Wealth shocks | $h^{Wm}$ | Back-shifted terms |

---

#### Worker-Searcher $h_\theta^{Wf}$ (f employed, m unemployed)

Symmetric to $h^{Wm}$ with $m \leftrightarrow f$ indices exchanged.

---

#### Dual-Employed $h_\theta^{EE}(w_m, w_f, a^J, a_m, a_f)$

**Outflows:**

| Channel | Rate | Destination |
|---------|------|-------------|
| m's job destroyed | $\delta_m$ | $h^{Wf}$ |
| f's job destroyed | $\delta_f$ | $h^{Wm}$ |
| m climbs ladder | $s_m^* \gamma_m [1 - F_m(w_m)]$ | Upward drift in $w_m$ |
| f climbs ladder | $s_f^* \gamma_f [1 - F_f(w_f)]$ | Upward drift in $w_f$ |
| Divorce | $\pi$ | Singles |
| Wealth shocks | $\mu_m, \mu_f$ | Reshuffled |

**Inflows:**

| Channel | Source | Expression |
|---------|--------|------------|
| f accepted from Wm | $h^{Wm}$ | $\lambda_f f_f(w_f) \, \mathbf{1}\{w_f \in \mathcal{A}_f^{EE}\} \cdot h^{Wm}(w_m, \cdot)$ |
| m accepted from Wf | $h^{Wf}$ | $\lambda_m f_m(w_m) \, \mathbf{1}\{w_m \in \mathcal{A}_m^{EE}\} \cdot h^{Wf}(w_f, \cdot)$ |
| Marriage | Singles | At $a^J = 0$, both employed |
| Wealth shocks | $h^{EE}$ | Back-shifted terms |

---

### Single States

#### Unemployed singles $g_i^U(a)$

**Outflows:**

| Channel | Rate |
|---------|------|
| Finds job | $\lambda_i(1 - F_i(w^{R,\sin}_i(a)))$ |
| Marriage | $\eta$ |
| Wealth shock | $\mu_i$ |

**Inflows:**

| Channel | Expression |
|---------|------------|
| Job destruction | $\delta_i \int g_i^E(w, a) \, dw$ |
| Divorce | $\pi \cdot \mathcal{D}_i^{U \leftarrow \text{div}}(a)$ |
| Wealth shock | $\mu_i \int_0^{\min(a, \bar{z}_i)} g_i^U(a - z) \, dG_i(z)$ |

**Full KFE:**

$$0 = -\partial_a[(ra + b_i - c^*) \, g_i^U] - [\lambda_i(1 - F_i(w^{R,\sin}_i)) + \mu_i + \eta] \, g_i^U$$
$$\quad + \mu_i \int_0^{\min(a, \bar{z}_i)} g_i^U(a - z) \, dG_i(z) + \delta_i \int g_i^E(w, a) \, dw + \pi \cdot \mathcal{D}_i^{U \leftarrow \text{div}}(a)$$

---

#### Employed singles $g_i^E(w, a)$

**Outflows:**

| Channel | Rate |
|---------|------|
| Job destruction | $\delta_i$ |
| Climbs ladder | $s_i^* \gamma_i [1 - F_i(w)]$ |
| Marriage | $\eta$ |
| Wealth shock | $\mu_i$ |

**Inflows:**

| Channel | Expression |
|---------|------------|
| From unemployed | $\lambda_i f_i(w) \, \mathbf{1}\{w \geq w^{R,\sin}_i(a)\} \cdot g_i^U(a)$ |
| Divorce | $\pi \cdot \mathcal{D}_i^{E \leftarrow \text{div}}(w, a)$ |
| Wealth shock | $\mu_i \int_0^{\min(a, \bar{z}_i)} g_i^E(w, a - z) \, dG_i(z)$ |

**Full KFE:**

$$0 = -\partial_a[(ra + w - c^*) \, g_i^E] - \partial_w[s_i^* \gamma_i f_i(w)(1 - F_i(w)) \, g_i^E]$$
$$\quad - [\delta_i + s_i^* \gamma_i (1 - F_i(w)) + \mu_i + \eta] \, g_i^E$$
$$\quad + \lambda_i f_i(w) \, \mathbf{1}\{w \geq w^{R,\sin}_i\} \, g_i^U + \pi \cdot \mathcal{D}_i^{E \leftarrow \text{div}}(w, a) + \text{[wealth shock inflow]}$$

---

### Divorce Inflow Terms

Under $\theta = O$ (universal community property):

$$\mathcal{D}_m^{U \leftarrow \text{div}}(a) = \pi \int\!\!\!\int\!\!\!\int h^{UU}(a^J, a_m', a_f') \cdot \mathbf{1}\left\{\frac{(1 - \tau_O)}{2}(a^J + a_m' + a_f') = a\right\} \, da^J \, da_m' \, da_f'$$

Under $\theta = L$ (limited community property):

$$\mathcal{D}_m^{U \leftarrow \text{div}}(a) = \pi \int\!\!\!\int\!\!\!\int h^{UU}(a^J, a_m', a_f') \cdot \mathbf{1}\left\{\frac{a^J}{2} + a_m' = a\right\} \, da^J \, da_m' \, da_f'$$

Analogous expressions hold for inflows from $Wm$, $Wf$, $EE$ states where spouse $i$ was unemployed/employed.

### Mass Conservation

$$\sum_\theta \int [h^{UU} + h^{Wm} + h^{Wf} + h^{EE}] + \int g_i^U \, da + \int\!\!\int g_i^E \, dw \, da = 1 \quad \text{for each gender } i$$

---

## Task 3: Forward and Backward Difference Approximations

Following Achdou et al. (2022), approximate the derivative of each value function w.r.t. assets using **upwind finite differences**.

### Definition

For a generic value function $V(a)$ on grid $\{a_1, \ldots, a_I\}$ with spacing $\Delta a_i = a_{i+1} - a_i$:

**Forward difference:**

$$V_a^{F,i} = \frac{V_{i+1} - V_i}{\Delta a_i}, \quad i = 1, \ldots, I-1$$

**Backward difference:**

$$V_a^{B,i} = \frac{V_i - V_{i-1}}{\Delta a_{i-1}}, \quad i = 2, \ldots, I$$

### Application to Each Value Function

| Value function | Derivatives needed |
|---|---|
| $U(a^J, a_m, a_f)$ | $U_{a^J}^F, \; U_{a^J}^B, \; U_{a_m}^F, \; U_{a_m}^B, \; U_{a_f}^F, \; U_{a_f}^B$ |
| $W_m(w_m, a^J, a_m, a_f)$ | Same 6 asset derivatives (wage grid handled separately) |
| $W_f(w_f, a^J, a_m, a_f)$ | Same |
| $E(w_m, w_f, a^J, a_m, a_f)$ | Same |
| $U_i^{\sin}(a)$ | $(U_i^{\sin})_a^F, \; (U_i^{\sin})_a^B$ |
| $E_i^{\sin}(w, a)$ | $(E_i^{\sin})_a^F, \; (E_i^{\sin})_a^B$ |

### Boundary Treatment

- At $a^J = \underline{a}^J$ (borrowing constraint): **forward difference only**
- At $a^J = \bar{a}^J$ (upper bound): **backward difference only**
- Same logic for $a$ in single problems and for $a_m$, $a_f$ at their respective bounds

---

## Task 4: Implied Savings from Forward/Backward Approximations

From each difference approximation, the FOC $u'(c^*) = V_a$ implies a consumption level, and hence a savings rate.

### Forward-Implied Savings

$$\dot{a}^{F,i} = r a_i + y - c^{F,i}, \quad \text{where } c^{F,i} = (u')^{-1}(V_a^{F,i})$$

### Backward-Implied Savings

$$\dot{a}^{B,i} = r a_i + y - c^{B,i}, \quad \text{where } c^{B,i} = (u')^{-1}(V_a^{B,i})$$

### Upwind Scheme Selection

This is the key numerical step. Choose the derivative based on the direction of the implied drift:

$$V_a^i = V_a^{F,i} \cdot \mathbf{1}\{\dot{a}^{F,i} > 0\} + V_a^{B,i} \cdot \mathbf{1}\{\dot{a}^{B,i} < 0\} + \bar{V}_a^i \cdot \mathbf{1}\{\dot{a}^{F,i} \leq 0 \text{ and } \dot{a}^{B,i} \geq 0\}$$

where $\bar{V}_a^i = u'(r a_i + y)$ is the "steady-state" derivative (zero savings).

**Logic:**

- **Forward difference** when drift is positive (agent is saving)
- **Backward difference** when drift is negative (agent is dissaving)
- **Steady-state marginal utility** when neither direction has the correct sign (agent is at a kink / zero-savings point)

### Income by Value Function

| Value function | Income $y$ in savings formula for $a^J$ | Individual account drift |
|---|---|---|
| $U$ (dual-unemployed) | $b_m + b_f$ | $\dot{a}_i = r a_i$ (always forward for $a_i > 0$) |
| $W_m$ (worker-searcher) | $w_m + b_f$ | $\dot{a}_i = r a_i$ |
| $W_f$ (worker-searcher) | $b_m + w_f$ | $\dot{a}_i = r a_i$ |
| $E$ (dual-employed) | $w_m + w_f$ | $\dot{a}_i = r a_i$ |
| $U_i^{\sin}$ (single unemp.) | $b_i$ | N/A (single account) |
| $E_i^{\sin}$ (single emp.) | $w$ | N/A (single account) |

For individual accounts in the couple problem, drift is $r a_i$ (deterministic between shocks). This is always positive for $a_i > 0$, so the **forward difference** is always used.

---

## Solution Pipeline Summary

```
Task 1: Policy functions (analytical for c*, s*; numerical for reservation wages)
   │
   ▼
Task 3: Discretize state space → forward/backward differences of V w.r.t. assets
   │
   ▼
Task 4: Implied savings + upwind selection → construct drift matrix A
   │
   ▼
Solve HJB: (ρI - A)V = u(c*) + option-value terms  [iterate to convergence]
   │
   ▼
Task 1 (update): Recompute reservation wages & acceptance sets from converged V
   │
   ▼
Task 2: Plug policies into KFEs → solve A'g = 0 for stationary distributions
   │
   ▼
Update marriage values M_i → re-solve HJBs → iterate outer loop
```
