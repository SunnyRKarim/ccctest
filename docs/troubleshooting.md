# Troubleshooting

* **Undetermined:** inspect status/reason and diagnostic fields. A constant-within-cell covariate is absorbed by the intercept; a category absent in a cell can leave its slope unidentified. Do not interpret a failed test as nonrejection or twoway evidence.
* **Stage 2 missing:** after Stage 1 nonrejection this is intended. Use alltests for unused diagnostics, which do not affect the homogeneous decision.
* **Disconnected cells:** one omitted time slope cannot identify global additive components in disconnected region-period patterns. Supply an identifiable sample or report the failure; do not silently add normalizations that change the null.
* **Too few preperiods:** narrow the focal cohort set or use a deliberately specified earlier untreated window. The original source fixture has only two common preperiods.
* **Bad date/cohort coding:** use ordered numeric periods and constant within-region first-treatment values, with explicit zero for never treated. Missing is unknown. Do not encode a real adoption as zero.
* **Tiny p-value:** a printed zero can be floating-point underflow. W and Q remain available; it is not a claim of mathematical zero probability.
* **Stata package not found:** use an absolute local path in net install, then which ccctest. Example data are ancillary files, not automatically installed by net install. Use the checked repository demo or net get beforehand.
* **R vignette build fails:** package use and source installation need no TeX; rebuilding documentation requires TeX on PATH. The development environment successfully used its existing MiKTeX installation. Windows locale warnings were eliminated for checks with LC_ALL=C.
* **Python optional plots unavailable:** install the plot extra. Importing and running the test needs only numpy, pandas and scipy. Tests use the repository's shared validation fixtures; run them from this checkout.
