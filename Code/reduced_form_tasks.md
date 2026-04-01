# Reduced Form Evidence: Marital Insurance and Job Search (DHS)

## Overview

The goal is to build reduced form evidence comparing job search behavior across:
1. Singles vs. couples (baseline heterogeneity)
2. Couples married before vs. after the 2018 Dutch property regime reform (DiD)

All plots should use shaded confidence intervals (95% CI). Use the `plotplain` scheme with the project's `grstyle` / `colorpalette` settings already defined in `descriptive_stats_dhs.do`. Graphs are exported to `${figures}`.

The working dataset for all tasks is `Worked/DHS_Work.dta` (individual-level) or `Worked/DHS_Work_uniquehh.dta` (household-collapsed). Start from `DHS_Work.dta` for richer variable access.

---

## Key Variable Dictionary (Work Module — `wrk{year}en`)

### Identifiers
| Variable | Description |
|----------|-------------|
| `nohhold` | Household identifier (use for clustering SEs) |
| `nomem` | Individual member index within household |
| `year` | Survey wave year (2010–2024) |

### Marital Status & Treatment
| Variable | Description |
|----------|-------------|
| `burgst` | Marital status: 1=community property, 2=separation of property (marriage settlement), 3=divorced, 4=cohabiting (not married), 5=widowed, 6=living apart together, 7=single |
| `jrbs` | Year of marriage/partnership registration (or divorce/cohabitation start) |
| `married` | Constructed: 1 if `burgst` ∈ {1,2} |
| `partner` | Constructed: 1 if `burgst` ∈ {1,2,4} |
| `single` | Constructed: 1 if `burgst` = 6 (or 7 in 2024) |
| `married_after2018` | Treatment indicator: 1 if `jrbs` ≥ 2018, 0 if `jrbs` < 2018 (among married only) |

### Employment Status
| Variable | Description |
|----------|-------------|
| `bezig_01` | =1 if paid job (multi-select from BEZIG_01 thru BEZIG_11) |
| `bezig_02` | =1 if looking for a job after having lost former job |
| `bezig_03` | =1 if looking for first-time work / work after long absence |
| `bet` | =1 if has paid job (even a few hours/week) |
| `ooitw` | =1 if ever had a paid job |
| `working` | Constructed: 1 if `bezig_01`==1 or `bet`==1 |
| `in_laborforce` | Constructed: 1 if working or looking for job |
| `looking_forjob` | Constructed: 1 if `zoek` ∈ {1,2} |

### Job Search Outcomes (Primary Outcomes of Interest)
| Variable | Description |
|----------|-------------|
| `hsol` | Number of job applications submitted (search intensity) |
| `zoek` | Actively searching: 1=looking after job loss, 2=looking for first-time/long-term |
| `rawerk01`–`rawerk11` | Reasons for working / not working (multi-select) |

### Reservation Wage
| Variable | Description |
|----------|-------------|
| `mlon1` | Minimum net monthly wage willing to accept (question 1) |
| `mlonp1` | Pay period for `mlon1`: 1=weekly, 2=4-weekly, 3=monthly, 4=yearly |
| `mloon` | Minimum net monthly wage willing to accept (question 2, alternative phrasing) |
| `mloonp` | Pay period for `mloon` |
| `rw_monthly` | Constructed monthly reservation wage (combining `mlon1` and `mloon`, harmonized to monthly) |

### Current Job Characteristics
| Variable | Description |
|----------|-------------|
| `netloon` | Net pay/salary at current job |
| `perloon` | Pay period for `netloon` |
| `loonm` | Monthly net wage (constructed) |
| `perloonm` | Pay period for `loonm` |
| `loond2` | Contract type: 1=permanent, 2=temporary, 3=stand-by, 4=temping, 5=self-employed/freelance |
| `uurwerk` | Actual hours worked per week (including overtime) |
| `uren` | Contractual hours per week |
| `zwerk` | Desired total hours per week |
| `bijbaan` | Has an additional/second job: 1=second paid job, 2=own business, 3=both, 4=no |
| `reis` | Commute time in minutes (one-way) |
| `jawerk` | Year started current job |
| `mawerk` | Month started current job |
| `branche` | Industry of current/last job (1–15 categories) |
| `dnb201` | Overall job satisfaction: 1=very satisfied … 5=very dissatisfied |

---

## Task 1: Singles vs. Couples — Job Search Outcomes

**Goal:** Document the baseline differences in job search behavior between singles and couples. This motivates why marital insurance could affect search. These are descriptive plots — no causal claims.

**Sample:** Full DHS sample 2010–2024. Show separately for: (a) all, (b) those actively looking for a job (`looking_forjob == 1`), (c) those in the labor force (`in_laborforce == 1`).

**Groups to compare:**
- `single == 1` (burgst = 6 or 7 in 2024)
- `married == 1` (burgst ∈ {1,2})
- `partner == 1` (burgst ∈ {1,2,4}) — cohabiting included

**Outcomes to plot (time series lines by group, 2010–2024, with 95% CI bands):**

### 1a. Reservation Wage
- Outcome: `rw_monthly`
- Drop outliers: `rw_monthly > 177770`
- Three subplots: unconditional, conditional on `looking_forjob == 1`, conditional on `working == 1`
- **Already exists** for simple mean lines without CI — add CI shading using `(rarea)` or `ciplot`

### 1b. Job Search Intensity
- Outcome: `hsol` (number of applications)
- Only meaningful for those looking for a job (`looking_forjob == 1` or `in_laborforce == 1`)
- **Already exists** as mean lines — add CI shading

### 1c. Job Contract Type (Risk-Taking Proxy)
- Outcome: share with permanent contract (`loond2 == 1`) vs. temporary/flexible (`loond2 ∈ {2,3,4}`)
- Interpretation: married workers should be more willing to take permanent/risky jobs if insurance is stronger
- Restrict to `working == 1`

### 1d. Actual vs. Desired Hours Gap
- Outcome: `zwerk - uurwerk` (hours gap; positive = would like to work more)
- Restrict to `working == 1`
- Interpretation: married workers with insurance may have lower urgency to maximize hours

### 1e. Commute Time
- Outcome: `reis` (minutes)
- Restrict to `working == 1`
- Interpretation: willingness to commute further = higher job ladder climbing effort
- **Already exists** as mean lines — add CI shading

### 1f. Job Satisfaction
- Outcome: `dnb201` (1=very satisfied, …, 5=very dissatisfied); recode to ascending satisfaction scale
- Restrict to `working == 1`
- Interpretation: insurance may allow workers to be more selective and end up in better jobs

### 1g. Additional Job (Moonlighting)
- Outcome: indicator `bijbaan ∈ {1,2,3}` (has secondary job)
- Restrict to `working == 1`
- Interpretation: singles may moonlight more due to weaker insurance

**Stata implementation notes:**
```stata
* For CI plots with shaded areas, use ciplot or collapse with sem then rarea:
collapse (mean) mean_outcome=outcome (semean) se_outcome=outcome, by(year group_var)
gen ci_lo = mean_outcome - 1.96*se_outcome
gen ci_hi = mean_outcome + 1.96*se_outcome
twoway (rarea ci_lo ci_hi year if group==1, color(%30)) ///
       (line mean_outcome year if group==1) ///
       (rarea ci_lo ci_hi year if group==2, color(%30)) ///
       (line mean_outcome year if group==2)
```

---

## Task 2: Pre-2018 vs. Post-2018 Couples — Reform Effect

**Goal:** Compare labor market outcomes for couples married before vs. after the 2018 reform. The 2018 reform changed the default property regime from universal to limited community property, weakening marital insurance for couples married after January 1, 2018.

**Key prediction from the model:**
- Weaker insurance → lower reservation wages
- Weaker insurance → more job applications (higher search intensity)
- Weaker insurance → more risk aversion in job market (e.g., prefer permanent contracts, shorter commute)

**Sample:** `married == 1` only. Use `married_after2018` (= 1 if `jrbs >= 2018`, = 0 if `jrbs < 2018`).

**Note on coding:** The current code uses `married_after2018` based on `jrbs >= 2018`. Confirm this is `jrbs` (year relationship started) and not `jbrs`. The 2023-2024 fix already handles `jbrs` → `jrbs` renaming.

**Groups:**
- `married_after2018 == 0`: married before reform (control group)
- `married_after2018 == 1`: married after reform (treatment group)
- Add `single == 1` as a reference benchmark (they should be unaffected by the reform)

**Add a vertical reference line at 2018** in all plots.

**Outcomes to plot (same as Task 1, time series 2010–2024 with 95% CI bands):**

### 2a. Reservation Wage by Marriage Cohort
- `rw_monthly`, by `married_after2018`
- Prediction: post-2018 couples have lower `rw_monthly`
- **Partly exists** — adapt the `married_after2014` graph already in code, use 2018 cutoff

### 2b. Job Search Intensity by Marriage Cohort
- `hsol` by `married_after2018`
- Prediction: post-2018 couples apply to more jobs
- **Partly exists** — adapt from existing `hsol` graph

### 2c. Contract Type by Marriage Cohort
- Share `loond2 == 1` (permanent), by `married_after2018`

### 2d. Commute Time by Marriage Cohort
- `reis`, by `married_after2018`

### 2e. Actual vs. Desired Hours Gap by Marriage Cohort
- `zwerk - uurwerk`, by `married_after2018`

### 2f. Job Satisfaction by Marriage Cohort
- `dnb201`, by `married_after2018`

**Simple DiD regression (for all outcomes):**
```stata
* Run on married sample only
reg outcome i.married_after2018 i.year, vce(cluster nohhold)

* With controls
reg outcome i.married_after2018 i.year i.branche, vce(cluster nohhold)

* Conditional on looking for a job
reg outcome i.married_after2018 i.year if looking_forjob == 1, vce(cluster nohhold)
```

**Also run by property regime (burgst):**
```stata
* burgst == 1: community property couple
* burgst == 2: separation of property couple
* Compare pre/post among community property holders (the default before reform)
```

---

## Task 3: Additional Outcomes from Work Module

The following additional outcomes are theoretically motivated by the proposal and available in the work module (`wrk{year}en`). These should be explored for both Tasks 1 and 2.

### 3a. Labor Force Participation
- Outcome: `in_laborforce` (binary)
- Motivation: Insurance may keep secondary earner out of the labor force (Aspen effect). Weaker insurance post-2018 may push both spouses to work.
- Group: compare by `married`/`single` and by `married_after2018`

### 3b. Transition to Self-Employment
- Outcome: indicator for `loond2 == 5` (self-employed/freelance) or `bezig_01 == 1` combined with `branche` type
- Motivation: Risk-taking in career. Insurance from spouse allows more entrepreneurial risk.
- Group: compare by `married`/`single` and by `married_after2018`

### 3c. Unemployment Spell Duration
- Outcome: Needs construction. Use `jawerk`/`mawerk` (year/month current job started) to infer how long the person was unemployed before current job.
- Requires linking to prior waves or using cross-sectional timing.
- Motivation: Higher reservation wages → longer unemployment spells for married couples.

### 3d. Industry Switching / Sector of Employment
- Outcome: `branche` (1–15 categories)
- Track share in high-risk/high-return sectors (financial=9, self-employed=15) by marital status and over time
- Motivation: Insurance allows more sectoral risk-taking.

### 3e. Reasons for Not Working (`rawerk01`–`rawerk11`)
- These capture why someone is not working (disability, household care, early retirement, etc.)
- Outcome: share citing each reason, by marital status
- Motivation: Insurance from spouse may enable one partner to stay home (specialization channel)

### 3f. Part-time vs. Full-time Work
- Outcome: `uurwerk < 32` (part-time, Dutch standard)
- Motivation: Couples with stronger insurance may have one part-time worker; post-2018 couples may both work full-time

### 3g. Desired Retirement Age
- Variable: `lftpens` (expected retirement age, in pension section of work module)
- Motivation: Weaker insurance post-2018 → may work longer to accumulate own individual assets

---

## Implementation Checklist

- [ ] **Task 1:** Update existing graphs (res wage, hsol, commute) to add 95% CI shading using `rarea`
- [ ] **Task 1:** Add new graphs: contract type, hours gap, job satisfaction, moonlighting (1c–1g)
- [ ] **Task 2:** Replace `married_after2014` with `married_after2018` throughout; add single as reference
- [ ] **Task 2:** Add vertical line at 2018 in all time-series plots
- [ ] **Task 2:** Run and tabulate DiD regressions for all outcomes
- [ ] **Task 3:** Add variables to `vars_to_keep` in the import loop: `loond2 uren uurwerk zwerk bijbaan branche dnb201 lftpens rawerk01 rawerk02 rawerk03 rawerk04 rawerk05 rawerk06 rawerk07 rawerk08 rawerk09 rawerk10 rawerk11`
- [ ] **Task 3:** Construct `hours_gap = zwerk - uurwerk`, `parttime = (uurwerk < 32)`, `selfempl = (loond2 == 5)`, `permanent = (loond2 == 1)`
- [ ] **All tasks:** Save all figures to `${figures}` with descriptive names (e.g., `rw_singles_couples_ci.pdf`, `hsol_pre_post2018_ci.pdf`)

---

## Graph Style Notes

All plots should follow the existing project conventions:
- Scheme: `plotplain`
- Colors: blue (`#1f77b4`) for married/control, red (`#d62728`) for single/reference, green for post-2018/treatment
- CI bands: same color as line with 30% opacity (`color(colorname%30)`)
- Add vertical line at 2018: `xline(2018, lpattern(dash) lcolor(gray))`
- Font: Palatino (`graph set window fontface "Palatino"`)
- Show N in text annotations (bottom-left of graph)
- Export as PDF to `${figures}/`
