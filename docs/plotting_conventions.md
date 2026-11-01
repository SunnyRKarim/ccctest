# Plotting conventions

Use a separate, common untreated window before the earliest focal adoption. Focal groups are future adopters, not currently treated individuals. Default comparisons are fixed never-treated regions. Complete endpoint support is required. Equal focal weights and equal control weights within each focal region are defaults; a supplied match table can replace them. These are software choices.

All four fits retain saturated cell intercepts. Adjusted cell means are mean(y)-(mean(z)-z_ref)'beta_j, for common, region, time and unrestricted cell slopes. Default z_ref=0; pooled and explicit design references are alternatives. Subtracting full fitted values is wrong: it creates zero cell means. Heterogeneous adjusted shapes can change when the reference changes.

Integrated changes always use unrestricted slopes. For each (focal s, control c, target t, baseline b), compute predictions in cells (s,t),(s,b),(c,t),(c,b), all at mean(z|s,t). Subtract within region, average controls within focal region, then average focal regions with the same weights on both sides. Use mean of the actual basis, including powers/dummies, not transformation of raw means. Record four predictions, coefficients, means and marginal range overlap diagnostics. Adjacent observed dates are labeled changes over the reported interval, never assumed annual. No confidence bands are supplied.

Levels and changes have distinct units/axes. These are diagnostics, not tests of identifying assumptions. Common-slope adjustment is not an exhaustive pointwise CPT test. IPT can hold while CPT fails; CCC violation alone does not establish IPT. Missing/unidentified requested panels are errors, not silently successful subsets.
