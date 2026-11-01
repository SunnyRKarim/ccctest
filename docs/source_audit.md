# Source audit

Audited the complete 67-page September 28, 2026 manuscript by Sunny Karim and the complete supplied simulation script, without importing or executing its notebook-level code. Page 52 was also rendered and checked visually.

| Original | SHA-256 |
|---|---|
| Third_Chapter (2).pdf | 788f97a2e95710a6145572227814b2ec2d892ec6109aba0637a3f8c2064db29f |
| Third Chapter Stage2 Sim.py | dbf52b83d2daf02a37b0e93b8cb4775ad8603c427bdf915581892212336f1fea |

Both hashes match the assignment. Originals remain unchanged; the PDF was located in Downloads and copied into ignored `reference/`. The script remains at repository root, ignored. Neither ships in packages.

Source-defined behavior: Assumptions 1–9 (pp. 5–7); saturated untreated-cell regression (114), equality restrictions (115)–(116), additive second stage (118), region equality (119)–(120), normalized time deviations (121)–(122), chi-square Wald inference (125)–(127), Table 1 (p. 29), two-test Holm procedure (pp. 29–30). Plot equations (147)–(149), p. 52, use the treated target-period distribution in all four predictions.

Verified discrepancies and conventions:

* The simulation discussion (pp. 35, 37) describes homoskedastic inference; `ccc_wald_tests` fits both models with HC1. HC1 is the software default; OLS is separately available.
* The script computes both stages before selection. Software gates Stage 2, with `alltests` for unused diagnostics.
* `safe_wald_test` catches all exceptions, and `choose_model_from_tests` can select twoway on nonfinite tests. Software returns undetermined for a required failure.
* Equation (132), p. 31, specifies only three mean coefficients for six dates. `generate_dgp` uses the six-entry `time_coef`; code-reference fixtures preserve that behavior.
* The paper has strict and non-strict rejection wording. Software consistently rejects at p <= alpha, as the executable selector does.
* The canonical public code is `region`; source `state` maps to it. Integrated Parallel Trends is current terminology; intersection is legacy wording.
* No plotting implementation accompanies the script. Equal fixed region/comparison weights and zero/common pooled design references are software conventions, not recovered empirical settings. Figures 5–6 cannot be replicated without their data/code.
* `estimate_didint_with_jackknife` calls an external, unsupplied DID-INT estimator; its t(G-1) inference and weights do not define CCC inference. No ATT adapter is provided.
* `run_one_replication` compares selected versus unrestricted ATT estimators. The script does not implement the chapter's separate power, heteroskedastic, sample-split or ACS exercises.

Official software references checked: [HC1](https://www.statsmodels.org/stable/generated/statsmodels.regression.linear_model.OLSResults.HC1_se.html), [Wald/use_f](https://www.statsmodels.org/stable/generated/statsmodels.regression.linear_model.RegressionResults.wald_test.html), [R Holm](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/p.adjust.html), [GitHub CLI](https://cli.github.com/manual/gh_repo_create). Native Stata installed help consulted for factor expansion and Mata linear solvers. These checks do not replace runtime validation.
