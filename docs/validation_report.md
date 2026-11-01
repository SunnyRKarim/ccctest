# Validation report

Checks ran on Windows 11, Intel64 Family 6 Model 167, 16 logical CPUs, approximately 64 GiB RAM. Python 3.14 with numpy 2.5.3, pandas 3.0.6, scipy 1.18.1, statsmodels 0.15.0; R 4.5.3; licensed StataNow 18.5 SE. Full Python environment is in validation/expected/python_environment.txt. Only these local runtime versions are verified; dependency bounds express supported API families, not a claim that every version was tested.

## Numerical references

The 1800-row original fixture was generated once by AST-extracting only generate_dgp and audited CCC helper definitions from the hash-verified source. No notebook statements, external DID-INT import, directory changes or Monte Carlo loop executed. Source HC1 results agreed with independently constructed dense QR fits. The original untreated sample has N=1200, U=24, P1=48, P2=35, and restriction counts 23/5/5.

An additional saved unbalanced K=2 fixture contains an absent cell, unequal cell sizes, nonconsecutive dates and identifiable additive structure. Production engines absorb cell intercepts but use full parameter counts in HC1/OLS. Both covariance options match dense reference calculations.

The cross-language audit compares 104 arrays across native Stata, R and Python: W/Q/raw/adjusted p-values and flags, both stages' slope coefficients and covariance matrices, both stages' intercepts, sample masks, restriction matrices, six-panel series, and every integrated-pair numeric field (four predictions, endpoint coefficients, target means, weights and overlap flags). Maximum absolute difference was 3.19e-11. Tolerances were set beforehand: coefficient/covariance/Wald atol=rtol=1e-8, p-value atol=1e-12 and rtol=1e-8. Decisions themselves use exact p<=alpha, never a tolerance. Machine-readable differences: validation/expected/cross_language_report.json.

## Native checks

* Stata: local net install into a fresh project ado directory; which/help availability; all four original outcomes under both covariances; independent numeric assertions; gatekeeping/alltests; exact decision/alpha/alpha-half/tie cases; rank and residual-df failures; disconnected Stage 2; duplicate/cell-constant regressors; factor expansion including nonlinear terms; string regions; status/cohort coherence; unsupported covariance requests; weighted matched controls; missing endpoint errors; preservation of data, RNG, working directory and prior e() results; six/core-panel graphs; original and eight-period offline demos. The full do-file and completion marker were checked, not just the Windows process exit code (Stata can exit 0 after a do-file error).
* Python: 31 pytest cases pass, including parameterized source/dense HC1/OLS comparisons, full covariance/intercept checks, independent dense checks of all four adjustments, region/row/reference recoding invariance, common nonsingular basis transformations, categorical expansion, every selection row, unavailable required/unused diagnostic tests, nonadditive interaction with neither Stage 2 rejection, singular covariance, eligibility/missing data, explicit weights rejection, and plot algebra/side effects. Editable install, source distribution, wheel build and separate wheel-target import passed.
* R: source installation and native tests passed. Full R CMD check, including examples, PDF manual and vignette rebuild, completed with **Status: OK**. Earlier missing vignette outputs and namespace notes were fixed. LC_ALL=C avoids this machine's inherited unsupported locale warnings. The reusable base-R graph is a recordedplot.

Actual native logs are retained locally in artifacts/root batch logs; sanitized statistical execution logs are saved under validation/logs. Exact entry points are in README. No unavailable runtime has been counted as passed. Stata 16/17/MP and other operating systems have not been tested locally. Hosted Ubuntu Python 3.12 (31 tests) and R 4.6.1 (Status: OK) CI passed for implementation commit 2bd3bd2 in the original private development repository. That historical run may not be publicly viewable. Hosted R skipped manual/vignette rebuilding; the full local R check included both. A new public GitHub Actions run is required before claiming CI status for the public repository.

## Plot audit

Numerical correctness is checked independently of graph existence. The eight-period demonstration is deliberately distinct from the source six-period DGP. Its deterministic noise is orthogonal to the cell basis, so known conditional means/slopes are recovered exactly. Tests verify ordinary parallel raw means; CPT with divergent raw means; IPT with unequal pointwise conditional trends; all four standardized predictions; target versus baseline/control distributions; mean(x²) versus mean(x)²; averaging predictions over individual treated target observations; fixed match weights and date intervals. Equivalent linear predictions use the actual basis. Stata, R and Python PNGs were visually inspected. No empirical ACS figure reproduction is claimed.

## Performance and pilot

Python HC1/alltests measured sequentially on synthetic U=24, K=1 designs:

| Input N | Untreated N | Seconds | Sampled peak process RSS |
|---:|---:|---:|---:|
| 1,800 | 1,200 | 0.0133 | 133 MB |
| 180,000 | 120,000 | 0.1174 | 158 MB |
| 1,080,000 | 720,000 | 0.7316 | 323 MB |

RSS was sampled every 10ms; short-lived peaks can be missed. Baseline fixture memory was included; these are one-run measurements, not stable performance guarantees. Hardware and full dimensions are in benchmark.json. No ACS-scale high-dimensional performance claim follows.

A 20-replication HC1 pilot at n_cell=50 had zero computational failures. Correct-selection frequencies (Monte Carlo standard errors) were homogeneous .75 (.097), region .80 (.089), time .95 (.049), twoway .90 (.067). In particular, the homogeneous selection frequency is not close enough to .95 to claim accurate nominal size from this tiny pilot. These results were retained without tuning seeds; the pilot is a reproducibility/smoke exercise, not a paper replication or power study. No 5000-replication run was launched. The resumable script supports configurable replications and an explicitly labeled heteroskedastic design; that optional design has not been run in this validation pass.

## Distribution audit

One public-source repository, three language directories. The supplied archive does not preserve the original private Git history. No nested repositories or submodules. Source manuscripts/script are ignored and excluded from installable packages. Original sanitized logs contain no known restricted microdata, authentication material or Stata license details. No open-source reuse license, package-registry upload, GitHub release or ATT adapter is represented as completed. See inference_limitations.md for known first-version limits.
