{smcl}
{title:ccctest — Common Causality of Covariates}
{pstd}Implementation of Sunny Karim (2026), equations (114)–(127). Requires Stata 18; tested on StataNow 18.5 SE. No external dependencies.
{title:Syntax}
{pstd}{cmd:ccctest} outcome covariates {cmd:, group(}region{cmd:) time(}period{cmd:) gvar(}cohort{cmd:)} [{cmd:vce(hc1)} {cmd:alpha(.05)} {cmd:alltests}]
{pstd}Supports if/in and factor variables (e.g. c.x i.category c.x#c.x). Alternatively specify {cmd:untreated(}indicator{cmd:)} (1=untreated, 0=treated). When both eligibility sources are supplied they must agree. Cohort 0 explicitly means never treated; missing is unknown. Dates must be ordered numeric values and must not include 0 with cohort coding. Regions can be strings. Cohorts must be constant within region. No treatment reversals.
{title:Method}
{pstd}The test uses complete currently untreated observations. Stage 1 compares K slopes across U observed cells, with saturated cell intercepts. Stage 2 uses the same sample, all region slopes and normalized time deviations (first observed date omitted). It tests region equality and zero time deviations from one additive fit. Stage 2 is gated unless alltests is requested.
{pstd}Default HC1 matches the supplied executable reference. {cmd:vce(ols)} or {cmd:vce(homoskedastic)} uses pooled homoskedastic covariance. Both retain all cell intercepts in residual degrees of freedom. Wald statistics use chi-square tails, not F tails. Reject p <= alpha. Stage 2 uses Holm adjustment on its two p-values only.
{pstd}Stage 1 nonrejection selects homogeneous. After rejection, region only selects region; time only selects time; both or neither selects twoway, with distinct reasons. A required rank/covariance failure returns undetermined. No generalized inverse or silent dropping of slopes. Near-singular cross-products (condition > 1e12) and more than 2000 slope parameters are rejected as unavailable.
{title:Stored results}
{pstd}{cmd:e(tests)} rows omnibus/region/time, columns W Q p p_holm reject performed used. Missing entries denote unperformed/unavailable results. {cmd:e(selected)}, {cmd:e(reason)}, {cmd:e(status)}, {cmd:e(diagnostic)} describe selection and failures. {cmd:e(sample)}, N, N_complete, excluded_eligibility, U, S, T, K, P1, P2, rank1, rank2 report sample/design diagnostics. Ranks refer to centered slope designs; total rank adds U. {cmd:e(slopes1)}, {cmd:e(V_slopes1)}, {cmd:e(intercepts1)}, {cmd:e(slopes2)}, {cmd:e(V_slopes2)}, {cmd:e(intercepts2)}, R1, R_region, R_time are auxiliary, not ATT results. Slopes are block-major: cell/region/time, then basis column. {cmd:e(cells)} contains sorted region code, period code and cell N. Basis names are in {cmd:e(basis)}.
{title:Interpretation and limitations}
{pstd}CCC is not a test of unconditional, conditional or Integrated Parallel Trends. Nonrejection does not prove CCC. HC1 is not cluster robust. Repeated person IDs do not handle serial dependence. Cluster/survey covariance and observation weights are unsupported. Treatment-affected covariates, misspecified conditional means and lack of overlap are not fixed by selecting a model. The chapter's post-selection simulation is not a general guarantee for ATT confidence intervals. No ATT estimator is included.
{title:Example}
{phang2}{cmd:ccctest y_state c.x, group(group) time(year) gvar(gvar)}
{phang2}{cmd:matrix list e(tests)}
{pstd}See {help ccctrends} for standalone diagnostics. See README and docs/conference_demo.md in the source repository for installation and offline demonstrations.
