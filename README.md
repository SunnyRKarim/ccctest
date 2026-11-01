# ccctest

**Version 0.1.0.** Native Stata, R and Python implementations of **Sunny Karim's Common Causality of Covariates (CCC) test**, with standalone untreated-trend diagnostics. This public repository is maintained by Sunny Karim. The software was developed with assistance from Matthew D. Webb and OpenAI Codex; see [AUTHORS.md](AUTHORS.md).

The implementation is based on Karim's September 28, 2026 manuscript and simulation script. Related methodological work: Karim and Webb (2024), *Good Controls Gone Bad: Difference-in-Differences with Covariates*. See the [installation and demonstration guide](docs/handoff.md).

The Stata implementation runs without Python, R, internet access or an external DID-INT estimator. All three implementations use the same statistical contract and saved numerical fixtures. No ATT estimator is bundled.

**CCC is not a test of parallel trends. HC1 is not cluster robust. Nonrejection does not prove a coefficient restriction.** These programs report a selected specification under maintained assumptions, not a known true model. See [inference limitations](docs/inference_limitations.md).

## Install and run Stata

After this repository has been published at `SunnyRKarim/ccctest`, installation directly from GitHub is possible in Stata:

```stata
net install ccctest, from("https://raw.githubusercontent.com/SunnyRKarim/ccctest/main/stata/") replace
which ccctest
help ccctest
```

To work from a local clone or extracted folder instead, use the following commands.

Tested with **StataNow 18.5 SE**, using `version 18` syntax. Other Stata versions/editions have not been runtime-tested. From the repository root in Stata:

```stata
net install ccctest, from("`c(pwd)'/stata") replace
which ccctest
help ccctest
import delimited "stata/examples/original.csv", clear asdouble
ccctest y_state c.x, group(group) time(year) gvar(gvar)
ccctrends y_state c.x, group(group) time(year) gvar(gvar) panels(all)
```

Offline presentation, from the repository root after installation:

```stata
capture mkdir artifacts
do stata/examples/conference_demo.do artifacts stata/examples/original.csv stata/examples/plots.csv
```

The first dataset is the exact saved six-region/six-period source fixture. The second is an explicitly labeled eight-period synthetic demonstration of IPT holding while pointwise CPT fails. No downloads or dependency installation occur during the demo. See the [presenter guide](docs/conference_demo.md). Uninstall with `ado uninstall ccctest`. `net install` installs commands/help; example data remain in the repository (or can be obtained beforehand using `net get`).

## Install and run R

In a shell from the repository root:

```text
R CMD INSTALL r
```

```r
library(ccctest)
d <- read.csv(system.file("extdata", "original.csv", package="ccctest"))
fit <- ccctest(y_state ~ x, d, "group", "year", "gvar")
print(fit)
tr <- ccc_trends(y_state ~ x, d, "group", "year", "gvar")
graph <- plot(tr, panels="all")
head(tr$pairs)
```

Use `?ccctest`, `?ccc_trends` and the [worked vignette](r/vignettes/quickstart.Rnw). Plot methods return a reusable `recordedplot`. Uninstall with `remove.packages("ccctest")`. The R package lists Sunny Karim as maintainer and acknowledges the software-development contributions separately in [AUTHORS.md](AUTHORS.md).

## Install and run Python

```text
python -m pip install "./python[plot]"
```

```python
import pandas as pd
from ccctest import ccc_test, ccc_trends
d = pd.read_csv("validation/fixtures/original.csv")
fit = ccc_test(d, "y_state", ["x"], group="group", time="year", cohort="gvar")
print(fit)
tr = ccc_trends(d, "y_state", ["x"], group="group", time="year", cohort="gvar")
tr.plot("all").savefig("trends.png")
tr.pairs.to_csv("integrated_audit.csv", index=False)
```

See [Python API conventions](python/README.md) and [fuller example](python/examples/worked.py). Uninstall with `python -m pip uninstall ccctest`.

## What is implemented

* Currently untreated complete-case sample, saturated cell intercepts/slopes, additive Stage 2, chi-square Wald inference, HC1/OLS, gated two-test Holm and all five valid decision rows.
* Multiple covariates and explicit design bases. Stata uses factor notation, R uses formulas, Python uses explicit categorical options and precomputed transformations/interactions.
* Three-panel overview, six-panel family and individual graphs; numeric series, coefficients, target moments, four standardized endpoint predictions, matched comparisons, weights and overlap flags.
* Rank/conditioning/resource diagnostics. Required failures are undetermined; unperformed tests remain missing. Coefficient/covariance results refer to auxiliary regressions, not treatment effects.
* Independent dense reference and isolated original-script comparisons. Native Stata/R/Python tests and local install/build checks.

The initial covariance default is HC1 to match the script, despite the paper's homoskedastic simulation description. Stage 2 is gated by default; `alltests` explicitly requests unused diagnostics. `region` is the canonical label for source `state`. The chapter calls the third concept **Integrated Parallel Trends**; “intersection” is legacy terminology. See [source audit](docs/source_audit.md), [statistical specification](docs/statistical_specification.md), [API contract](docs/api_contract.md) and [plot conventions](docs/plotting_conventions.md).

## Validation and support

Run `do stata/tests/run_all.do` in Stata; `python -m pytest python/tests -q`; and `R CMD build r` followed by `R CMD check ccctest_0.1.0.tar.gz`. Building the R vignette/manual requires an existing TeX installation; using the package does not. Cross-language reproduction: run `stata/tests/cross_language.do`, `validation/scripts/cross_language.R`, then `validation/scripts/compare_exports.py`. The R export script uses the project-local `artifacts/rlib` installation.

See [validation report](docs/validation_report.md), [current status](STATUS.md), and [troubleshooting](docs/troubleshooting.md). The source distribution contains synthetic demonstration data and no restricted microdata or manuscript. This repository is public source code, **not** a release on SSC, CRAN or PyPI. The software is source-available under a restrictive license permitting installation and execution of unmodified copies for research, teaching, and evaluation, but not modification or redistribution. See [LICENSE](LICENSE). The earlier private-development validation is documented, but public GitHub Actions status should be checked independently.
