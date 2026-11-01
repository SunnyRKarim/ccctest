version 18
clear all
set more off
adopath ++ "stata"
program define exportmatrix
    args matrixname filename
    preserve
    clear
    svmat double `matrixname'
    export delimited using "`filename'", replace novarnames
    restore
end
foreach fixture in original unbalanced {
    import delimited "validation/fixtures/`fixture'.csv", clear asdouble
    local vars y_state x
    if "`fixture'"=="unbalanced" local vars y x z
    foreach vce in HC1 OLS {
        ccctest `vars', group(group) time(year) gvar(gvar) vce(`vce') alltests
        matrix result=e(tests)
        exportmatrix result artifacts/stata_`fixture'_`vce'_tests.csv
        preserve
        generate byte mask=e(sample)
        export delimited mask using "artifacts/stata_`fixture'_`vce'_mask.csv", replace novarnames
        restore
        foreach restriction in R1 R_region R_time {
            matrix result=e(`restriction')
            exportmatrix result artifacts/stata_`fixture'_`vce'_`restriction'.csv
        }
        foreach stage in 1 2 {
            matrix result=e(slopes`stage')
            exportmatrix result artifacts/stata_`fixture'_`vce'_b`stage'.csv
            matrix result=e(V_slopes`stage')
            exportmatrix result artifacts/stata_`fixture'_`vce'_V`stage'.csv
            matrix result=e(intercepts`stage')
            exportmatrix result artifacts/stata_`fixture'_`vce'_theta`stage'.csv
        }
    }
}
foreach fixture in original plots {
    import delimited "validation/fixtures/`fixture'.csv", clear asdouble
    local vars y_state x
    if "`fixture'"=="plots" local vars ipt x x2
    ccctrends `vars', group(group) time(year) gvar(gvar) nograph ///
        csv("artifacts/stata_`fixture'_series.csv") replace
    matrix result=r(pairs)
    preserve
    clear
    svmat double result, names(col)
    export delimited using "artifacts/stata_`fixture'_pairs.csv", replace
    restore
}
file open passed using artifacts/stata_cross_passed.txt, write replace
file write passed "Cross-language exports completed" _n
file close passed
exit,clear
