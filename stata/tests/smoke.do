version 18
clear all
set more off
adopath ++ "stata"
import delimited "validation/fixtures/original.csv", clear asdouble
ccctest y_state x, group(group) time(year) gvar(gvar) alltests
assert e(N)==1200
assert e(U)==24
assert e(P1)==48
assert e(P2)==35
matrix list e(tests)
assert "`e(status)'"=="ok"
ccctrends y_state x, group(group) time(year) gvar(gvar) panels(all) name(demo) replace export("validation/expected/stata_demo.png")
matrix list r(series)
exit, clear
