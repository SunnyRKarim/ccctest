# Release and demonstration guide: v0.1.0

Public repository target: https://github.com/SunnyRKarim/ccctest. This package is a public-source continuation of the original private development snapshot with the project maintained by Sunny Karim. This archive does not include the original private repository's Git history or tags. A newly created Git repository starts a new history; no public package-registry upload is asserted.

## Exact installation and demonstrations

Run these from the repository root. In Stata:

```stata
net install ccctest, from("`c(pwd)'/stata") replace
capture mkdir artifacts
do stata/examples/conference_demo.do artifacts stata/examples/original.csv stata/examples/plots.csv
```

In a shell with R available:

```text
R CMD INSTALL r
Rscript r/inst/doc/quickstart.R
```

For R graphs, run:

```r
library(ccctest)
d <- read.csv(system.file("extdata", "plots.csv", package="ccctest"))
tr <- ccc_trends(ipt ~ x + x2, d, "group", "year", "gvar")
png("r_trends.png", width=1500, height=1000)
plot(tr, panels="all")
dev.off()
```

In a shell with Python available:

```text
python -m pip install "./python[plot]"
python python/examples/worked.py
```

Stata commands are `ccctest` and `ccctrends`, with native help files. R exposes `ccctest()` and `ccc_trends()` plus accessors and print/plot methods; Python exposes `ccc_test()` and `ccc_trends()` with structured result objects. README and native documentation describe their options. Numeric graph data and integrated prediction audits are returned by the plotting APIs. The Stata demo exports CSV/DTA/PNG/GPH; verified snapshots are in `examples/expected_outputs`. The original development build checksums are retained in `validation/expected/package_sha256.json` for historical reference, not as checksums of newly built distribution files. No prebuilt distribution artifacts are included in this source ZIP.

## Verification and scope

The conference demonstration is ready on the tested StataNow 18.5 SE installation: a fresh local installation, native numerical/edge-case tests, offline demo and figure inspection all passed. Other Stata versions/editions remain untested. Python has 31 passing tests, successful editable/wheel installations and distribution builds. R 4.5.3 full package check, including manual and vignette, returned Status: OK. Native cross-language exports passed 104 array comparisons, maximum absolute discrepancy 3.19e-11. See `validation/logs` and `docs/validation_report.md` for original validation; the new public repository's CI should be checked following the first push.

The manuscript and executable reference differ on covariance, gating, failure fallback, one mean sequence and boundary wording. Implementations use documented HC1 by default with OLS available, gated Stage 2 with optional diagnostics, explicit undetermined failures and p <= alpha. Plot normalization/weights are explicit software conventions. `docs/source_audit.md` records each discrepancy and the provenance hashes.

CCC does not test parallel trends; HC1 is not cluster robust. The initial release omits survey/observation weights, clustered inference, confidence bands and ATT estimation. Dates require numeric encoding. Stata plots use fixed never-treated controls and currently fit all adjustment models even for a raw-only graph. High-dimensional covariance remains dense with a 2000-slope safeguard. No empirical ACS replication, 5000-replication study or general post-selection inference guarantee is claimed. The full methodological and implementation limits are in `docs/inference_limitations.md`.
