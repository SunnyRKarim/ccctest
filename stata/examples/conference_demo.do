version 18
// Run after installation; pass an explicit output directory (default current).
args output data plotdata
if `"`output'"'=="" local output "."
clear
set more off
if `"`data'"'=="" local data "original.csv"
import delimited using "`data'", clear asdouble
ccctest y_state c.x, group(group) time(year) gvar(gvar)
matrix list e(tests)
ccctrends y_state c.x, group(group) time(year) gvar(gvar) panels(all) ///
    name(ccc_conference) saving("`output'/ccc_trends.dta") ///
    csv("`output'/ccc_trends.csv") export("`output'/ccc_trends.png") replace
matrix list r(pairs)
graph save ccc_conference "`output'/ccc_trends.gph", replace
if `"`plotdata'"'!="" {
    import delimited using "`plotdata'", clear asdouble
    ccctrends ipt x x2, group(group) time(year) gvar(gvar) panels(all) ///
        name(ccc_ipt) csv("`output'/ipt_trends.csv") export("`output'/ipt_trends.png") replace
    matrix audit=r(pairs)
    mata: assert(max(abs(st_matrix("audit")[.,11]-st_matrix("audit")[.,12]))<1e-8)
    graph save ccc_ipt "`output'/ipt_trends.gph", replace
    ccctrends cpt x x2, group(group) time(year) gvar(gvar) panels(core) ///
        name(ccc_cpt) csv("`output'/cpt_trends.csv") export("`output'/cpt_trends.png") replace
}
display "Offline conference demonstration completed."
