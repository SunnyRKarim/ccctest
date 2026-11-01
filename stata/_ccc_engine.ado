program define _ccc_engine
    version 18
    capture mata: ccc_map(1,1,1,1,1,1,1,"H")
    if _rc {
        findfile _ccc_engine.mata
        quietly run "`r(fn)'"
    }
end
