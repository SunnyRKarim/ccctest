# Offline presenter guide

Install and test before the presentation. Stata commands and Mata functions are native; no live network, external estimator or other language is used. Start a clean Stata session in the repository root, run the README installation once, then:

```stata
do stata/examples/conference_demo.do artifacts stata/examples/original.csv stata/examples/plots.csv
```

Create `artifacts` first if it does not exist. The demo deliberately clears the dataset and exports named files with replace. The reusable commands themselves preserve user data; `ccctrends` also preserves preceding estimation results, RNG state and working directory.

1. **CCC table.** The saved source fixture has 1800 observations, 1200 untreated, 24 observed untreated cells and one covariate. Stage 1 has 48 parameters and 23 restrictions; Stage 2 has 35 parameters with five region and five time restrictions. Explain W as a chi-square Wald statistic, p as the raw tail, p_holm as the second-stage adjustment, and performed versus used. For y_state/HC1: W1=37.741528, p1=0.02714581; region W=14.387889, Holm p=0.02664892; time W=8.704652, Holm p=0.12144054. The selection is region, not an ATT estimate.
2. **Original six panels.** The common prewindow is just periods 1–2, because earliest adoption is period 3. It therefore has only one integrated change. Do not call this a compelling pretrend assessment; it illustrates why a common support window matters.
3. **Eight-period extension.** The separately labeled synthetic file has one focal region (adopts in period 10), two never-treated controls and eight preperiods. Its IPT outcome has pointwise conditional trend differences but equal integrated changes. Explain that all four predictions use the focal target-period distribution. The two integrated curves coincide algebraically and numerically; the other panels need not.
4. **CPT example.** The cpt outcome has a common linear-in-basis conditional mean trend, while raw means diverge because covariate distributions differ. Adjustment recovers parallel curves. This is an illustration with known coefficients, not evidence that a real-data plot proves CPT.

Outputs: `ccc_trends.png/.gph/.dta/.csv`, `ipt_trends.png/.gph/.csv`, and `cpt_trends.png/.csv`. Native `.gph` files remain editable. Pairwise predictions and coefficients are accessible immediately in r(pairs); copy them before another r-class command overwrites r().

The extension uses x with treated mean mu_t=t/4, x² as a second basis, and three slope sequences beta_s,t=s*t. Control 2 intercept increments are 2, focal increments are 2+mu_t, and control 3 increments are 2-mu_t. Every integrated change equals 2+2mu_t. Pointwise focal-minus-control-2 trend differences equal mu_t-x, so CPT fails away from the target mean. The x² coefficient is common and constant. Deterministic noise is orthogonal to the cell basis, making these exact finite-sample checks. The ordinary outcome uses fixed_x with constant distribution and parallel raw means.

Readiness is based on licensed StataNow 18.5 SE clean-install, native test and demo runs. The demo was also exported and visually reviewed. Retest on the actual presentation computer; other Stata editions/versions are not runtime-verified here.
