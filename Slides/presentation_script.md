# Presentation Script
**Marital Insurance and Job Search: Evidence from Property Regime Reform**
Sofia Valdivia & Heleen Ren — February 2026

> Left column: what is on the slide. Right column: what to say (~1.5 min per slide).

---

## Slide 1 — Title

| **Slide** | **Script** |
|---|---|
| *Marital Insurance and Job Search: Evidence from Property Regime Reform* | "Good [morning/afternoon]. I'm Sofia Valdivia, and today I'll present joint work with Heleen Ren on marital insurance and job search. The central question is whether the legal design of marriage — specifically the property regime — shapes how couples search for jobs. Our empirical setting is a 2018 Dutch reform that changed the default matrimonial property regime." |

---

## Slide 2 — The Core Question

| **Slide** | **Script** |
|---|---|
| Married individuals search differently: higher reservation wages, faster job-ladder climbing, greater risk-taking. Spousal income provides insurance — but the literature treats this as fixed. We ask: does the *strength* of marital insurance matter? | "Start with a well-established fact: married workers behave very differently in the labor market. They hold out for higher wages, climb the job ladder faster, and take on more labor market risk. The canonical explanation — going back to Guler, Guvenen & Violante — is that the spouse's income acts as insurance. If you can rely on your partner's paycheck, you don't need to jump at the first offer you receive. But here's the gap: the existing literature treats marital insurance as a binary — you're either married or you're not. Nobody asks what if the insurance *within* marriage varies. That's exactly what we do. The matrimonial property regime is essentially the fine print of the marriage contract, and it determines how much financial risk couples actually pool." |

---

## Slide 3 — Why a Structural Model?

| **Slide** | **Script** |
|---|---|
| **Reason 1:** Marital insurance is unobservable — operates through expectations, divorce probability, and savings. DiD can't disentangle the channels. **Reason 2:** Job search is dynamic — reservation wages, search intensity, and unemployment duration are joint equilibrium objects. | "You might ask: why not just run a difference-in-differences around the 2018 reform and call it a day? Two reasons. First, marital insurance is not directly observable. The reform changes what happens *if* the couple divorces. But the effect on job search today operates through forward-looking expectations — couples internalize the divorce risk even while happily married. A reduced-form comparison can tell you something changed, but it can't tell you *why*. Second, job search is inherently dynamic. Reservation wages, search intensity, and unemployment duration are all connected. When you change the property regime, you move all of these simultaneously. Only a structural model lets us discipline all the channels at once and run meaningful counterfactuals." |

---

## Slide 4 — Dutch Matrimonial Property Regimes

| **Slide** | **Script** |
|---|---|
| **Universal CP (before 2018):** all assets jointly owned, equal division at divorce. **Limited CP (after 2018):** only assets acquired during marriage are shared; premarital assets, inheritances, gifts stay individual. Net effect: effective marital insurance falls. | "Until 2018, the Dutch default was Universal Community Property — every asset, including premarital savings, inheritances, and gifts, was jointly owned and split equally upon divorce. Strong insurance. In January 2018, the default changed to Limited Community Property. Now only assets accumulated during the marriage are shared. Premarital assets, inheritances, and gifts remain with the individual spouse. The key implication is that the reform weakens the financial insurance provided by marriage. A spouse who receives an inheritance is now shielded from sharing it if the marriage dissolves — but that also means the other spouse can no longer rely on that inheritance as a buffer." |

---

## Slide 5 — The 2018 Reform as a Natural Experiment

| **Slide** | **Script** |
|---|---|
| ~80% of couples stay on the default; no sorting around 2018. Treatment: post-2018 (L) vs. pre-2018 (U). Interaction: couples with larger individual wealth shocks face a bigger reduction in pooling. Illustrative example: an inheritance stays individual under L, gets split under U. | "What makes this reform useful for identification? About 80% of Dutch couples stay on whatever the default is — they don't opt into a marriage settlement. And the data show no evidence of sorting around 2018, meaning couples didn't strategically time their weddings in response to the change. This gives us a clean treatment: couples who married after January 2018 face the Limited regime; those who married before face Universal. The second layer of variation comes from individual wealth shocks like inheritances. Under Universal CP, an inheritance gets split at divorce. Under Limited CP, it stays with the recipient. Same inheritance, different insurance loss depending on the regime. This lets us trace the insurance channel separately from a simple pre-post level change." |

---

## Slide 6 — Related Literature

| **Slide** | **Script** |
|---|---|
| Five key papers: Guler et al. (2012), Mankart & Oikonomou (2017), Pilossoph & Wee (2021), Fernández-Blanco (2022), Lise (2012) & Wang (2019). **Our departure:** we vary insurance strength rather than comparing singles vs. couples. | "Let me position us in the literature. We build directly on Guler, Guvenen & Violante's joint-search model, where spousal income as insurance raises reservation wages. Pilossoph and Wee extend this to show income pooling also accelerates job-ladder climbing. Fernández-Blanco shows the same insurance mechanism increases risk-taking. What's new here? All of these papers compare singles to couples — as if the insurance provided by marriage is fixed. We instead ask: what happens when you vary the *degree* of that insurance within marriage? That's the contribution. The property regime is the lever." |

---

## Slide 7 — Model: Overview

| **Slide** | **Script** |
|---|---|
| Unitary couple, continuous time, infinite horizon. State space: wages, joint & individual assets, employment statuses, property regime θ. Key primitives: δᵢ, λᵢ, γᵢ, Fᵢ, κ(·), μᵢ, π. | "Now for the model. We model a unitary household consisting of two spouses in continuous time. They maximize expected discounted utility over joint consumption. The state space captures everything relevant: both spouses' wages, the joint and individual asset holdings, their employment statuses, and the property regime θ. This last element is the novel ingredient — θ enters every value function and governs how divorce payoffs are computed. The key primitives include job destruction and offer arrival rates, on-the-job search with a convex cost function borrowed from Lise and Wang, wealth shock arrival rates, and a Poisson divorce rate π." |

---

## Slide 8 — Model: Three Employment Cases

| **Slide** | **Script** |
|---|---|
| Diagram: Dual Unemployed ↔ Worker-Searcher ↔ Dual Employed. Transitions via job offers (up) and job destruction (down). Breadwinner cycle from Guler et al. All cases coupled by joint savings and divorce threat. | "The model has three employment cases. We go from Dual Unemployed, to a Worker-Searcher pair — one spouse employed and also searching on the job — to Dual Employed. Job destruction moves the couple back down, job offers move them up. What's important is that all three cases are coupled. The savings decision is always joint, and the threat of divorce is always present. The property regime θ affects the divorce payoff in each case, which in turn shapes search incentives throughout. You also see the breadwinner cycle: an employed spouse may quit to allow the unemployed spouse to take a better offer. We incorporate that here too." |

---

## Slide 9 — Model: Case 1 — Dual Unemployed

| **Slide** | **Script** |
|---|---|
| Value function U(·) with job offer terms, wealth shock terms, and divorce term. Reservation wage wᵢᴿ defined by Wᵢ(wᵢᴿ, …) = U(…). | "In Case 1, both spouses are unemployed and searching. The value function is standard: they consume, good things can happen — either spouse gets a job offer — and divorce arrives at rate π. The key object is the reservation wage. Under Universal CP, the divorce payoff is generous and symmetric, so the value of staying unemployed is high, and the reservation wage is high. Under Limited CP, that divorce payoff shrinks for the lower-wealth spouse, lowering the value of unemployment and therefore the reservation wage. This is the first channel through which the property regime affects labor market behavior." |

---

## Slide 10 — Model: Case 2 — Worker-Searcher

| **Slide** | **Script** |
|---|---|
| Employed spouse searches on-the-job at intensity sₘ. FOC pins down optimal search intensity. **Key:** under Limited CP, a wealth shock to the unemployed spouse does not improve the employed spouse's divorce payoff — muting the insurance benefit and lowering search intensity. | "Case 2 is the most interesting. One spouse is employed and also searches on the job. The FOC for optimal search intensity equates the marginal cost of effort to the expected gain from a better wage draw. Here's the key mechanism: under Universal CP, an inheritance received by the unemployed spouse gets pooled — it improves both spouses' divorce payoff and raises the value of the marriage for both. That strengthens the insurance buffer and encourages the employed spouse to search more ambitiously. Under Limited CP, that same inheritance stays individual. It doesn't improve the employed spouse's divorce payoff at all. The insurance benefit is muted, and on-the-job search intensity falls." |

---

## Slide 11 — Model: Case 3 — Dual Employed

| **Slide** | **Script** |
|---|---|
| Both spouses employed and searching on the job. Same structure as Case 2, extended symmetrically. Divorce threat and property regime operate through continuation values. | "Case 3 extends the same logic to both spouses simultaneously. Both choose their on-the-job search intensities, accounting for the possibility that a better wage offer comes for either spouse and that accepting it may trigger the breadwinner cycle. The divorce threat and the property regime continue to operate in the background through the continuation values." |

---

## Slide 12 — Model: Divorce Value Functions

| **Slide** | **Script** |
|---|---|
| Under θ = U: aᵢᴰ = ½(1−τᵤ)(aᴶ + aₘ + aƒ) — full pooling, higher dissolution costs. Under θ = L: aᵢᴰ = ½aᴶ + aᵢ — partial pooling, zero dissolution cost. | "This slide shows the precise heterogeneity introduced by the property regime. Under Universal CP, all assets are pooled and split equally at divorce, minus dissolution costs τᵤ. Even if one spouse built up more individual savings, the other gets half. Under Limited CP, only jointly-held savings are split. Each spouse keeps their own individual assets. The dissolution cost is zero here, but the insurance is weaker because wealth shocks that landed in an individual account never enter the divorce calculation. This asymmetry drives all the comparative statics we predict." |

---

## Slide 13 — Model: Singles and Outside Option

| **Slide** | **Script** |
|---|---|
| After divorce, each spouse solves a standard single-agent search problem with assets aᵢᴰ. Singles' reservation wage defined by Uᵢˢⁱⁿ = Eᵢˢⁱⁿ(wᵢᴿˢⁱⁿ, a). | "After divorce, each spouse becomes a single agent, taking as given the assets they received under the regime. This outside option feeds back into the married couple's value functions through Vₘᴰ and Vƒᴰ. The reform changes aᵢᴰ under Limited CP, and that propagates backward through all the married-couple value functions — altering search behavior throughout the entire marriage, not just at the moment of divorce. That anticipation effect is invisible to reduced-form methods." |

---

## Slide 14 — Comparative Statics

| **Slide** | **Script** |
|---|---|
| When insurance weakens: wᵢᴿ↓, unemployment duration↓, on-the-job search↓, transitions to risky occupations↓. Strongest effects for: high premarital wealth asymmetry, high divorce risk. | "Putting the model together: when marital insurance weakens, four things happen. Reservation wages fall, so workers accept jobs faster and unemployment spells are shorter. On-the-job search intensity falls, meaning slower wage growth. And transitions into riskier occupations fall, as couples hedge against the reduced insurance buffer. These effects are strongest when there is high asymmetry in premarital wealth — because those are the couples where Limited CP bites most — and when divorce risk is high, because anticipation of divorce matters more." |

---

## Slide 15 — Data: DNB Household Survey

| **Slide** | **Script** |
|---|---|
| Dutch panel, 2,000+ households/year since 1993. Self-reported reservation wages, unemployment duration, job-offer acceptance, transitions to self-employment. Wealth: joint vs. individual accounts, marital regime, inheritances. Limitation: sample shrinks after restricting to both spouses in labor force. | "For data, we use the DNB Household Survey. It's a Dutch panel tracking over 2,000 households per year since 1993. What makes it uniquely suited is that it has two things rarely observed together: granular job search behaviors — including self-reported reservation wages and job-offer acceptance decisions — and detailed wealth data that distinguishes joint from individual accounts. It also records whether a couple is on the default regime or a prenuptial settlement, and we can see inheritances and gifts, which are critical for our second source of identification. The limitation is sample size: once we restrict to couples where both spouses participate in the labor force and classify them into employment states, the sample shrinks substantially — hence the CBS linkage." |

---

## Slide 16 — Data: CBS Microdata & Linking Strategy

| **Slide** | **Script** |
|---|---|
| CBS: full-population panel — wages, employment spells, tax records. Regional housing price indices → premarital asset appreciation. Sector unemployment rates → variation in λᵢ, δᵢ. Linking: DHS for behavioral richness, CBS for statistical power. | "The CBS administrative microdata covers the entire Dutch population — wages, employment spells, firm identifiers, and tax records. This solves the sample size problem. Particularly useful are regional housing price indices, which proxy premarital equity — a wealth shock that is individual under Limited CP but shared under Universal CP, and plausibly exogenous to individual job search decisions. Sector-level unemployment rates give us variation in job arrival and destruction rates across couples. The idea is that linking DHS's behavioral richness to CBS's statistical power gives us the best of both worlds." |

---

## Slide 17 — Preliminary Data Patterns

| **Slide** | **Script** |
|---|---|
| Fig. 1: Default (common property) ≈80% across all years, no jump around 2018. Fig. 2: Marriage type distribution stable over time. Both support exogeneity of the reform. | "These preliminary patterns are reassuring for identification. The share of couples on the default regime is stable at around 80% throughout the sample — no visible discontinuity around 2018. If couples had sorted into the new Limited default because they expected inheritances or had high premarital assets, we'd see a spike. We don't. That supports the reform as an exogenous shift in the regime couples face." |

---

## Slides 18–20 — Suggested Additional Data Work

| **Slide** | **Script** |
|---|---|
| Eight proposed empirical exercises: staggered DiD, inheritance event study, continuous pooling treatment, cohabitors as control, housing wealth channel, gender asymmetry, sector interaction, precautionary savings response. | "Let me briefly walk through the additional empirical work we're planning. First, a staggered DiD using marriage cohort as treatment timing, tracing reservation wages and job-to-job transitions before and after the reform. Second, an inheritance event study: we identify households that receive an inheritance and track job search in event time, comparing the response under Universal versus Limited CP — the model predicts a larger reservation wage response under Universal. Third, the share of joint accounts as a continuous measure of insurance intensity. Beyond that, cohabiting couples serve as a natural 'pure separate' benchmark. The housing wealth channel, gender asymmetry tests, and precautionary savings response further pin down the insurance mechanism." |

---

## Slide 21 — Counterfactual Analysis

| **Slide** | **Script** |
|---|---|
| Five post-estimation counterfactuals: (1) full reversion to Universal CP; (2) shut down divorce risk; (3) shut down wealth shocks; (4) means-tested divorce asset floor; (5) aggregate labor market effects. | "Once the model is estimated, we plan five counterfactual exercises. The first restores Universal CP to post-2018 couples, recovering the welfare value of the old regime in terms of unemployment duration and wage growth. The second shuts down divorce risk entirely, isolating how much of the insurance mechanism works through the divorce threat versus income pooling during marriage. The third zeros out wealth shocks, asking how much of the regime effect runs through inheritances and gifts. The fourth tests a policy: would a public divorce asset floor offset the welfare loss of moving to Limited CP? Finally, we embed the estimated behavioral responses in a search-and-matching framework to ask about aggregate unemployment and wage inequality." |

---

## Slide 22 — Roadmap

| **Slide** | **Script** |
|---|---|
| Step 1: DHS descriptives & CBS linkage. Step 2: Solve model, characterize predictions. Step 3: SMM estimation. Step 4: Counterfactuals & welfare. Step 5: Robustness. | "In terms of where we are: we're currently at Step 1 — finalizing the DHS descriptive patterns and planning the CBS linkage. Step 2 is to solve the model numerically using value function iteration and characterize its qualitative predictions. Steps 3 through 5 cover estimation, counterfactuals, and robustness. We're happy to discuss any of these steps — particularly the open questions around the unitary assumption and how to handle non-participation." |

---

## Slide 23 — Conclusion

| **Slide** | **Script** |
|---|---|
| We ask whether the legal strength of marital insurance shapes job search. Exploit 2018 Dutch reform + inheritance shocks. Structural household search model with θ as a treatment parameter. **Bottom line: marriage law is labor market policy.** | "Let me conclude. This paper asks a simple but under-explored question: does the legal design of marriage affect how couples search for jobs? We exploit a Dutch property regime reform and individual wealth shocks to provide causal evidence. The punchline: marriage law is labor market policy. When you weaken asset pooling at divorce, couples start behaving more like singles — lower reservation wages, less on-the-job search, less labor market risk-taking — even while they are still married. A structural model is the only tool that can measure this anticipation effect. Thank you. Happy to take questions." |
