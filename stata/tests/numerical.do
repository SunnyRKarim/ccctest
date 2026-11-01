ccctest y_homogeneous x, group(group) time(year) gvar(gvar) vce(HC1) alltests
assert abs(e(tests)[1,1]-(24.438132994230976))<1e-8
assert abs(e(tests)[1,3]-(0.37988974905263589))<1e-12
assert abs(e(tests)[2,1]-(1.4548845381371378))<1e-8
assert abs(e(tests)[2,3]-(0.91821666980424177))<1e-12
assert abs(e(tests)[3,1]-(8.70465160616431))<1e-8
assert abs(e(tests)[3,3]-(0.1214405372086126))<1e-12
ccctest y_homogeneous x, group(group) time(year) gvar(gvar) vce(OLS) alltests
assert abs(e(tests)[1,1]-(23.14775718287191))<1e-8
assert abs(e(tests)[1,3]-(0.45217070123762171))<1e-12
assert abs(e(tests)[2,1]-(1.319511335358623))<1e-8
assert abs(e(tests)[2,3]-(0.93291122843353957))<1e-12
assert abs(e(tests)[3,1]-(8.9919289110121579))<1e-8
assert abs(e(tests)[3,3]-(0.1093865199121023))<1e-12
ccctest y_state x, group(group) time(year) gvar(gvar) vce(HC1) alltests
assert abs(e(tests)[1,1]-(37.741528388283662))<1e-8
assert abs(e(tests)[1,3]-(0.027145805809809999))<1e-12
assert abs(e(tests)[2,1]-(14.387889173045767))<1e-8
assert abs(e(tests)[2,3]-(0.0133244583074349))<1e-12
assert abs(e(tests)[3,1]-(8.7046516061643331))<1e-8
assert abs(e(tests)[3,3]-(0.1214405372086115))<1e-12
ccctest y_state x, group(group) time(year) gvar(gvar) vce(OLS) alltests
assert abs(e(tests)[1,1]-(39.688227262179851))<1e-8
assert abs(e(tests)[1,3]-(0.016652412676700201))<1e-12
assert abs(e(tests)[2,1]-(15.742082217407599))<1e-8
assert abs(e(tests)[2,3]-(0.0076203499331613002))<1e-12
assert abs(e(tests)[3,1]-(8.9919289110121809))<1e-8
assert abs(e(tests)[3,3]-(0.1093865199121012))<1e-12
ccctest y_time x, group(group) time(year) gvar(gvar) vce(HC1) alltests
assert abs(e(tests)[1,1]-(46.752565946724921))<1e-8
assert abs(e(tests)[1,3]-(0.0024083597149148002))<1e-12
assert abs(e(tests)[2,1]-(1.454884538137144))<1e-8
assert abs(e(tests)[2,3]-(0.91821666980424121))<1e-12
assert abs(e(tests)[3,1]-(27.073455272177569))<1e-8
assert abs(e(tests)[3,3]-(5.5193991586177559e-05))<1e-12
ccctest y_time x, group(group) time(year) gvar(gvar) vce(OLS) alltests
assert abs(e(tests)[1,1]-(45.15598040769553))<1e-8
assert abs(e(tests)[1,3]-(0.0038033259973945998))<1e-12
assert abs(e(tests)[2,1]-(1.319511335358629))<1e-8
assert abs(e(tests)[2,3]-(0.9329112284335388))<1e-12
assert abs(e(tests)[3,1]-(29.790619936486845))<1e-8
assert abs(e(tests)[3,3]-(1.6216167947565626e-05))<1e-12
ccctest y_twoway x, group(group) time(year) gvar(gvar) vce(HC1) alltests
assert abs(e(tests)[1,1]-(62.683393837375043))<1e-8
assert abs(e(tests)[1,3]-(1.5496813132728026e-05))<1e-12
assert abs(e(tests)[2,1]-(13.704056822080071))<1e-8
assert abs(e(tests)[2,3]-(0.017602695627798801))<1e-12
assert abs(e(tests)[3,1]-(32.086023670369364))<1e-8
assert abs(e(tests)[3,3]-(5.7127094502570124e-06))<1e-12
ccctest y_twoway x, group(group) time(year) gvar(gvar) vce(OLS) alltests
assert abs(e(tests)[1,1]-(67.341765342185681))<1e-8
assert abs(e(tests)[1,3]-(3.1069349304630455e-06))<1e-12
assert abs(e(tests)[2,1]-(14.761879956741398))<1e-8
assert abs(e(tests)[2,3]-(0.011429749218366999))<1e-12
assert abs(e(tests)[3,1]-(35.453119331758352))<1e-8
assert abs(e(tests)[3,3]-(1.2216880225514426e-06))<1e-12
