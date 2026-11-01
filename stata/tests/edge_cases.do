_ccc_engine
mata: assert(ccc_decision(.2,.,.,.05)[1]=="homogeneous")
mata: assert(ccc_decision(.05,.025,.7,.05)[1]=="region")
mata: assert(ccc_decision(.01,.7,.025,.05)[1]=="time")
mata: assert(ccc_decision(.01,.025,.05,.05)[2]=="holm_both")
mata: assert(ccc_decision(.01,.025,.025,.05)[2]=="holm_both")
mata: assert(ccc_decision(.01,.3,.4,.05)[2]=="holm_neither")
mata: assert(ccc_decision(.,.01,.01,.05)[2]=="stage1_failure")
mata: assert(ccc_decision(.01,.,.01,.05)[2]=="stage2_failure")
preserve
keep if year<=2
bysort group year: keep if _n==1
ccctest y_state x, group(group) time(year) gvar(gvar)
assert "`e(selected)'"=="undetermined"
assert "`e(diagnostic)'"=="insufficient_residual_df"
restore
preserve
keep if (group<=2 & year<=2) | (group>=5 & year>=5)
replace gvar=0
replace y_state=y_state+50*group*x
ccctest y_state x, group(group) time(year) gvar(gvar) alltests
assert "`e(reason)'"=="stage2_failure"
restore
preserve
replace x=group
ccctest y_state x, group(group) time(year) gvar(gvar)
assert "`e(status)'"=="undetermined"
restore
preserve
generate byte u=(d==0)
replace u=1 if group==1 & year==6
capture ccctest y_state x, group(group) time(year) untreated(u)
assert _rc==459
restore
preserve
drop if group==5 & year==1
quietly regress y_state x
matrix previous=e(b)
local N=_N
capture ccctrends y_state x, group(group) time(year) gvar(gvar) nograph
assert _rc==459
assert _N==`N'
assert mreldif(previous,e(b))==0
restore
matrix matched=(1,5,.1,.3 \ 1,6,.1,.7 \ 2,5,.2,.3 \ 2,6,.2,.7 \ 3,5,.3,.3 \ 3,6,.3,.7 \ 4,5,.4,.3 \ 4,6,.4,.7)
ccctrends y_state x, group(group) time(year) gvar(gvar) matchmatrix(matched) nograph
matrix pair=r(pairs)
matrix series=r(series)
mata: assert(abs(sum(st_matrix("pair")[.,12]:*st_matrix("pair")[.,5]:*st_matrix("pair")[.,6])-st_matrix("series")[11,5])<1e-10)
