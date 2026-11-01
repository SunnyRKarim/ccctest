# ccctest

Native Python implementation of Sunny Karim's Common Causality of Covariates procedure. Maintained in Sunny Karim's public repository. The source is publicly visible and may be installed and executed unmodified for research, teaching, and evaluation, but modification and redistribution are not authorized. See the root LICENSE file.

Install with `python -m pip install ./python`. Optional graphs: `python -m pip install './python[plot]'`.

```python
import pandas as pd
from ccctest import ccc_test, ccc_trends
d = pd.read_csv('validation/fixtures/original.csv')
fit = ccc_test(d, 'y_state', ['x'], group='group', time='year', cohort='gvar')
print(fit)
trends = ccc_trends(d, 'y_state', ['x'], group='group', time='year', cohort='gvar')
fig = trends.plot(panels='all')
fig.savefig('trends.png')
```

Use `categorical=['category']` with that column included in covariates to expand indicators (sorted first level is the base). Numeric columns remain continuous unless explicitly categorical. Supply transformations/interactions as precomputed numeric columns, e.g. `d['x2']=d.x**2`; integration averages that actual basis. A redundant/constant basis is invalid, never silently dropped. Dates are ordered numeric values (encode calendar dates with a documented unit). Cohort 0 explicitly means never treated, and time 0 is rejected with cohort coding. Alternatively supply `untreated='flag'` (1=untreated). Optional `subset` is a positional Boolean mask. Unknown eligibility and missing complete cases are reported separately.

`fit.tests` is a table; `fit.selected`, `fit.reason`, `fit.status`, `fit.diagnostics`, `fit.sample`, `fit.fits`, `fit.restrictions`, `fit.basis` expose calculations. `alltests=True` computes unused Stage 2 diagnostics. HC1 is default; `vce='OLS'`/`'homoskedastic'` uses homoskedastic covariance. Wald p-values are chi-square; decisions use p <= alpha and two-test Holm. An unavailable required fit/test gives undetermined. Test nonrejection does not establish CCC or parallel trends.

`ccc_trends` accepts `focal`, `window=(first,last)`, `matches={focal: {control: weight}}`, `focal_weights={focal: weight}`, `reference='zero'|'pooled'|array`, and `controls='never'|'notyet'`. Fixed control sets must remain untreated throughout the window. Returns `series`, `pairs` (all four standardized predictions, basis moments and endpoint coefficients), `cells`, `coefficients`, `matches`, `reference`, and `diagnostics`. `plot()` lazily imports matplotlib and returns its Figure. File overwrite policy belongs to the caller's explicit `savefig`/`to_csv` operation.

The CCC test is not a parallel-trends test. HC1 is not cluster robust. Weights, clustering, survey inference and ATT estimation are unsupported. The chapter does not establish general validity of selected-model ATT confidence intervals. See the repository's docs for maintained assumptions, plotting conventions, source discrepancies and validation results. Uninstall: `python -m pip uninstall ccctest`.
