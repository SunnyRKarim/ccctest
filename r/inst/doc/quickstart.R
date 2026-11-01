### R code from vignette source 'quickstart.Rnw'

###################################################
### code chunk number 1: setup
###################################################
library(ccctest)
d <- read.csv(system.file("extdata","original.csv",package="ccctest"))
fit <- ccctest(y_state ~ x, d, "group", "year", "gvar")
print(fit)


###################################################
### code chunk number 2: trends
###################################################
tr <- ccc_trends(y_state ~ x, d, "group", "year", "gvar")
head(tr$series)
head(tr$pairs[, c("pred_st","pred_sb","pred_ct","pred_cb")])
