*! Pretrend diagnostics 0.1.0
program define ccctrends, rclass sortpreserve
    version 18
    syntax varlist(min=2 numeric fv) [if] [in], GROUP(varname) TIME(varname numeric) GVAR(varname numeric) ///
        [CONTROLS(string) PANELS(string) NAME(name) SAVING(string) CSV(string) EXPORT(string) ///
        REPLACE NOGRAPH REFERENCE(string) MATCHMatrix(name)]
    if "`controls'"=="" local controls never
    if "`controls'"!="never" {
        di as error "This version requires fixed never-treated controls."
        exit 198
    }
    if "`panels'"=="" local panels core
    if !inlist("`panels'","core","all","raw","homogeneous","region","time","twoway","integrated") exit 198
    if "`name'"=="" local name ccc_trends
    if "`reference'"=="" local reference zero
    foreach path in saving csv export {
        if "``path''"!="" & "`replace'"=="" confirm new file "``path''"
    }
    marksample touse
    gettoken outcome basis : varlist
    _ccc_prepare, touse(`touse') group(`group') time(`time') gvar(`gvar')
    quietly summarize `gvar' if `touse' & `gvar'!=0 & !missing(`gvar'), meanonly
    if r(N)==0 exit 2000
    local first=r(min)
    quietly replace `touse'=0 if `time'>=`first'
    quietly count if `touse'
    if r(N)==0 exit 2000
    quietly fvexpand `basis' if `touse'
    local expanded `r(varlist)'
    quietly fvrevar `expanded' if `touse'
    local allvars `r(varlist)'
    local terms
    local xvars
    local pos 0
    foreach term of local expanded {
        local ++pos
        _ms_parse_parts `term'
        if !r(omit) {
            local terms `terms' `term'
            local x : word `pos' of `allvars'
            local xvars `xvars' `x'
        }
    }
    local K : word count `xvars'
    tempvar s t
    quietly egen long `s'=group(`group') if `touse', label
    quietly egen long `t'=group(`time') if `touse'
    quietly levelsof `s', local(codes)
    foreach code of local codes {
        local group_`code' : label (`s') `code'
    }
    _ccc_engine
    capture mata: ccc_trends_loaded()
    if _rc {
        quietly findfile _ccc_trends.mata
        quietly run "`r(fn)'"
    }
    tempname series pairs coefs cellmeans refmat matches
    local plot_error
    mata: ccc_trends_run("`s' `t' `outcome' `xvars' `time' `gvar'","`touse'","`reference'","`matchmatrix'")
    if "`plot_error'"!="" {
        di as error "`plot_error'"
        exit 459
    }
    matrix colnames `series'=panel time baseline treated control gap
    matrix colnames `matches'=focal control focal_weight control_weight
    local pairnames focal control time baseline focal_weight control_weight pred_st pred_sb pred_ct pred_cb delta_t delta_c
    forvalues k=1/`K' {
        local pairnames `pairnames' mu`k'
    }
    foreach endpoint in st sb ct cb {
        local pairnames `pairnames' theta_`endpoint'
        forvalues k=1/`K' {
            local pairnames `pairnames' beta_`endpoint'`k'
        }
    }
    matrix colnames `pairs'=`pairnames' outside_st outside_sb outside_ct outside_cb
    preserve
    quietly clear
    quietly svmat double `series', names(col)
    quietly levelsof time, local(plotdates)
    if "`saving'"!="" quietly save "`saving'", `replace'
    if "`csv'"!="" quietly export delimited using "`csv'", `replace'
    if "`nograph'"=="" {
        local ids 1 2 6
        if "`panels'"=="all" local ids 1 2 3 4 5 6
        local titles Unconditional Homogeneous Region-varying Time-varying Two-way Integrated
        local options raw homogeneous region time twoway integrated
        forvalues j=1/6 {
            local option : word `j' of `options'
            if "`panels'"=="`option'" local ids `j'
        }
        local graphs
        foreach j of local ids {
            local title : word `j' of `titles'
            local units "`outcome' level"
            local note "Reference: `reference'; fixed region weights"
            if `j'==6 {
                local units "`outcome' change"
                local note "Adjacent periods; see baseline dates in data"
            }
            tempname graph`j'
            quietly twoway (connected treated time if panel==`j', lcolor(navy) msymbol(O)) ///
                (connected control time if panel==`j', lcolor(maroon) msymbol(T) lpattern(dash)), ///
                title("`title'") ytitle("`units'", size(small)) xtitle("Period", size(small)) ylabel(,angle(horizontal) labsize(small)) xlabel(`plotdates',labsize(small)) ///
                legend(order(1 "Focal treated" 2 "Controls") rows(1) size(small) position(6)) ///
                note("`note'", size(vsmall)) name(`graph`j'', replace)
            local graphs `graphs' `graph`j''
        }
        graph combine `graphs', cols(3) xsize(12) ysize(8) title("Untreated trend diagnostics", size(medium)) graphregion(margin(large)) ///
            note("Diagnostics do not establish parallel trends. No confidence bands.") name(`name', `replace')
        if "`export'"!="" {
            local resolution
            if lower(substr("`export'",-4,.))==".png" local resolution width(2400)
            graph export "`export'", name(`name') `replace' `resolution'
        }
        foreach graph of local graphs {
            quietly graph drop `graph'
        }
    }
    restore
    return matrix series=`series'
    return matrix pairs=`pairs'
    return matrix coefficients=`coefs'
    return matrix cells=`cellmeans'
    return matrix reference=`refmat'
    return matrix matches=`matches'
    return scalar N=`plot_N'
    return scalar K=`K'
    return local basis "`terms'"
    foreach code of local codes {
        return local group_`code' "`group_`code''"
    }
end
