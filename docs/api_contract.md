# API contract (0.1 development)

Stata: `ccctest outcome covariates [if] [in], group(var) time(var) gvar(var) [untreated(var) vce(hc1|ols|homoskedastic) alpha(.05) alltests]`. At least one eligibility source is required; both must agree. Stata factor-variable notation creates one common basis. `e(tests)` columns are W, Q, p, p_holm, reject, performed, used. Missing is unperformed/unavailable, not nonrejection. `e(selected)`, `e(reason)`, `e(status)` and design/sample metadata accompany slope coefficients/covariance.

Canonical selections: homogeneous, region, time, twoway, undetermined. Status: ok or undetermined. Reasons: stage1_nonrejection, holm_region_only, holm_time_only, holm_both, holm_neither, stage1_failure, stage2_failure. An unused diagnostic failure is separate.

`ccctrends` is standalone and returns numeric tables; panels core/all or individual names, fixed controls and common pretreatment window. All graph functions preserve the input dataset and prior estimation. See native help and README for exact implemented optional syntax.

R: formula-based `ccctest()` and `ccc_trends()`; Python: `ccc_test()` and `ccc_trends()` with explicit covariate columns. Python categorical expansions are explicit, and transformations/interactions can be supplied as precomputed numeric design columns. Statistical and plotting conventions above apply to every language.
