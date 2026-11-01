program define _ccc_prepare, rclass sortpreserve
    version 18
    syntax, TOUSE(varname) GROUP(varname) TIME(varname numeric) [GVAR(varname numeric) UNTREATED(varname numeric)]
    if "`gvar'`untreated'"=="" {
        di as error "Specify gvar() (0=never) or untreated(); full data are not assumed untreated."
        exit 198
    }
    tempvar lo hi bad status
    if "`gvar'"!="" {
        quietly count if `touse' & `time'==0
        if r(N) {
            di as error "time=0 conflicts with the explicit never-treated code; recode time and cohorts."
            exit 459
        }
        quietly bysort `group': egen double `lo'=min(`gvar')
        quietly bysort `group': egen double `hi'=max(`gvar')
        quietly count if `touse' & `lo'!=`hi' & !missing(`group')
        if r(N) {
            di as error "Cohort must be constant within policy region."
            exit 459
        }
        drop `lo' `hi'
        quietly generate byte `status'=(`gvar'==0 | `time'<`gvar') if !missing(`gvar',`time')
    }
    if "`untreated'"!="" {
        quietly count if `touse' & !inlist(`untreated',0,1,.)
        if r(N) exit 459
        quietly bysort `group' `time': egen double `lo'=min(`untreated')
        quietly bysort `group' `time': egen double `hi'=max(`untreated')
        quietly count if `touse' & `lo'!=`hi'
        if r(N) {
            di as error "Untreated status must be coherent within region-period cells."
            exit 459
        }
        drop `lo' `hi'
        quietly bysort `group' (`time'): generate byte `bad'=sum(`untreated'==0)>0 & `untreated'==1
        quietly count if `touse' & `bad'
        if r(N) {
            di as error "Treatment reversals are unsupported."
            exit 459
        }
        if "`gvar'"!="" {
            quietly count if `touse' & !missing(`untreated',`status') & `untreated'!=`status'
            if r(N) exit 459
            quietly replace `touse'=0 if missing(`untreated')
        }
        else quietly generate byte `status'=`untreated'
    }
    markout `touse' `group' `time', strok
    quietly replace `touse'=0 if `status'!=1
end
