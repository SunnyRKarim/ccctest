*! CCC test 0.1.0, Sunny Karim's method
program define ccctest, eclass sortpreserve
    version 18
    if replay() {
        if "`e(cmd)'"!="ccctest" exit 301
        di as text "CCC selected specification: " as result "`e(selected)' (`e(reason)')"
        matlist e(tests), format(%12.6g)
        exit
    }
    syntax varlist(min=2 numeric fv) [if] [in], GROUP(varname) TIME(varname numeric) ///
        [GVAR(varname numeric) UNTREATED(varname numeric) VCE(string) ALPHA(real .05) ALLTESTS]
    if !(`alpha'>0 & `alpha'<1) exit 198
    if "`vce'"=="" local vce hc1
    local vce=lower("`vce'")
    if "`vce'"=="homoskedastic" local vce ols
    if !inlist("`vce'","ols","hc1") {
        di as error "Only unweighted OLS or HC1 is supported. Cluster/survey CCC inference is not developed."
        exit 198
    }
    gettoken outcome basis : varlist
    marksample restricted, novarlist
    quietly count if `restricted'
    local N_restricted=r(N)
    local N_input=_N
    marksample touse
    quietly count if `touse'
    local N_complete=r(N)
    local eligible
    if "`gvar'"!="" local eligible `eligible' gvar(`gvar')
    if "`untreated'"!="" local eligible `eligible' untreated(`untreated')
    _ccc_prepare, touse(`touse') group(`group') time(`time') `eligible'
    quietly count if `touse'
    local N=r(N)
    if !`N' error 2000
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
    if !`K' exit 198
    tempvar s t
    quietly egen long `s'=group(`group') if `touse', label
    quietly egen long `t'=group(`time') if `touse'
    quietly summarize `s', meanonly
    local S=r(max)
    quietly summarize `t', meanonly
    local T=r(max)
    if min(`S',`T')<2 {
        di as error "At least two observed untreated regions and periods are required."
        exit 459
    }
    quietly levelsof `s', local(codes)
    foreach code of local codes {
        local group_`code' : label (`s') `code'
    }
    quietly levelsof `time' if `touse', local(periods)
    tempname tests b1 V1 b2 V2 cells theta theta2 r1 rr rt restriction_ranks
    local P2 .
    local rank2 .
    local condition2 .
    _ccc_engine
    mata: ccc_test_run("`s' `t' `outcome' `xvars'","`touse'","`vce'",`alpha',"`alltests'"!="")
    ereturn post, esample(`touse') obs(`N')
    matrix rownames `tests'=omnibus region time
    matrix colnames `tests'=W Q p p_holm reject performed used
    ereturn matrix tests=`tests'
    ereturn matrix cells=`cells'
    matrix colnames `restriction_ranks'=omnibus region time
    ereturn matrix restriction_ranks=`restriction_ranks'
    capture confirm matrix `b1'
    if !_rc {
        ereturn matrix slopes1=`b1'
        ereturn matrix V_slopes1=`V1'
        ereturn matrix intercepts1=`theta'
        ereturn matrix R1=`r1'
    }
    capture confirm matrix `b2'
    if !_rc {
        ereturn matrix slopes2=`b2'
        ereturn matrix V_slopes2=`V2'
        ereturn matrix intercepts2=`theta2'
        ereturn matrix R_region=`rr'
        ereturn matrix R_time=`rt'
    }
    foreach item in U K S T P1 P2 rank1 rank2 condition1 condition2 N_input N_restricted N_complete {
        ereturn scalar `item'=``item''
    }
    ereturn scalar excluded_eligibility=`N_complete'-`N'
    ereturn scalar excluded_outcome_basis=`N_restricted'-`N_complete'
    ereturn scalar alpha=`alpha'
    ereturn local selected "`selected'"
    ereturn local reason "`reason'"
    ereturn local diagnostic "`diagnostic'"
    ereturn local status=cond("`selected'"=="undetermined","undetermined","ok")
    ereturn local basis "`terms'"
    ereturn local periods "`periods'"
    foreach code of local codes {
        ereturn local group_`code' "`group_`code''"
    }
    ereturn local vce "`vce'"
    ereturn local cmd ccctest
    ccctest
end
