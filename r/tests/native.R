library(ccctest)
d <- read.csv(system.file("extdata","original.csv",package="ccctest"))
expected <- read.csv(system.file("extdata","expected.csv",package="ccctest"))
for(outcome in unique(expected$outcome)) for(vce in c("HC1","OLS")) {
  fit <- ccctest(as.formula(paste(outcome,"~x")),d,"group","year","gvar",vce=vce,alltests=TRUE)
  e <- expected[expected$outcome==outcome & expected$vce==vce,]
  stopifnot(max(abs(fit$tests$W-e$W))<1e-8,max(abs(fit$tests$p-e$p))<1e-12)
  stopifnot(fit$diagnostics$N==1200,fit$diagnostics$P1==48,fit$diagnostics$P2==35)
}
stopifnot(ccctest(y_homogeneous~x,d,"group","year","gvar")$tests$performed[2]==0)
stopifnot(ccctest(y_state~x+I(x),d,"group","year","gvar")$status=="undetermined")
f <- ccctest(y_state~x+factor(id%%3)+I(x^2),d,"group","year","gvar",alltests=TRUE)
stopifnot(f$diagnostics$K==4,f$status=="ok")
select <- getFromNamespace(".select","ccctest")
stopifnot(select(.05,.025,.05,.05)[2]=="holm_both",select(.01,.2,.3,.05)[2]=="holm_neither")
stopifnot(select(.2,NA,NA,.05)[1]=="homogeneous",select(.01,NA,.1,.05)[1]=="undetermined")
set.seed(123); state <- .Random.seed; cwd <- getwd(); old <- d
tr <- ccc_trends(y_state~x,d,"group","year","gvar")
stopifnot(identical(state,.Random.seed),identical(cwd,getwd()),identical(d,old))
stopifnot(max(abs(tr$pairs$delta_t-tr$pairs$pred_st+tr$pairs$pred_sb))<1e-12)
stopifnot(max(abs(tr$pairs$delta_c-tr$pairs$pred_ct+tr$pairs$pred_cb))<1e-12)
stopifnot(any(abs(tr$series$treated)>1))
cat("Native R tests passed\n")
