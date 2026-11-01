version 18
clear all
set more off
capture mkdir artifacts
capture mkdir artifacts/stata_install
net set ado "`c(pwd)'/artifacts/stata_install"
net install ccctest, from("`c(pwd)'/stata") replace
adopath ++ "`c(pwd)'/artifacts/stata_install"
which ccctest
which ccctrends
import delimited "validation/fixtures/original.csv", clear asdouble
do stata/tests/numerical.do
do stata/tests/edge_cases.do
ccctest y_homogeneous x, group(group) time(year) gvar(gvar)
assert "`e(selected)'"=="homogeneous"
assert e(tests)[2,6]==0
assert missing(e(tests)[2,3])
ccctest y_homogeneous x, group(group) time(year) gvar(gvar) alltests
assert e(tests)[2,6]==1
assert e(tests)[2,7]==0
local rng `c(rngstate)'
local pwd `c(pwd)'
local N=_N
quietly regress y_state x
matrix prior=e(b)
ccctrends y_state x, group(group) time(year) gvar(gvar) panels(all) ///
    name(checked) csv("artifacts/stata_plot.csv") export("artifacts/stata_plot.png") replace
assert _N==`N'
assert "`rng'"=="`c(rngstate)'"
assert "`pwd'"=="`c(pwd)'"
assert mreldif(prior,e(b))==0
matrix audit=r(pairs)
assert abs(audit[1,11]-(audit[1,7]-audit[1,8]))<1e-12
assert abs(audit[1,12]-(audit[1,9]-audit[1,10]))<1e-12
generate double duplicate=x
ccctest y_state x duplicate, group(group) time(year) gvar(gvar)
assert "`e(status)'"=="undetermined"
capture ccctest y_state x, group(group) time(year) gvar(gvar) vce(cluster)
assert _rc==198
capture ccctest y_state x, group(group) time(year)
assert _rc==198
generate byte untreated=(d==0)
ccctest y_state x, group(group) time(year) untreated(untreated)
assert "`e(selected)'"=="region"
tostring group, generate(string_group)
ccctest y_state x, group(string_group) time(year) gvar(gvar)
assert "`e(selected)'"=="region"
generate byte category=mod(id,3)
ccctest y_state c.x i.category c.x#c.x, group(group) time(year) gvar(gvar) alltests
assert e(K)==4
assert "`e(status)'"=="ok"
replace gvar=7 in 1
capture ccctest y_state x, group(group) time(year) gvar(gvar)
assert _rc==459
do stata/examples/conference_demo.do artifacts stata/examples/original.csv stata/examples/plots.csv
file open passed using "artifacts/stata_passed.txt", write replace
file write passed "Stata native tests and offline demonstration passed." _n
file close passed
exit, clear
