args <- commandArgs(trailingOnly=TRUE)
.libPaths(c("artifacts/rlib",.libPaths()))
library(ccctest)
write_matrix <- function(x,path) write.table(x,path,sep=",",row.names=FALSE,col.names=FALSE,na="")
for(fixture in c("original","unbalanced")) {
  d <- read.csv(paste0("validation/fixtures/",fixture,".csv"))
  form <- if(fixture=="original") y_state~x else y~x+z
  for(vce in c("HC1","OLS")) {
    f <- ccctest(form,d,"group","year","gvar",vce=vce,alltests=TRUE)
    prefix <- paste0("artifacts/r_",fixture,"_",vce,"_")
    write_matrix(as.matrix(f$tests),paste0(prefix,"tests.csv"))
    write_matrix(as.numeric(f$sample),paste0(prefix,"mask.csv"))
    for(j in seq_len(3)) write_matrix(f$restrictions[[c("omnibus","region","time")[j]]],paste0(prefix,c("R1","R_region","R_time")[j],".csv"))
    for(stage in 1:2) {
      a <- f$fits[[paste0("stage",stage)]]
      write_matrix(t(a$beta),paste0(prefix,"b",stage,".csv"))
      write_matrix(a$covariance,paste0(prefix,"V",stage,".csv"))
      write_matrix(a$intercepts,paste0(prefix,"theta",stage,".csv"))
    }
  }
}
for(fixture in c("original","plots")) {
  d <- read.csv(paste0("validation/fixtures/",fixture,".csv"))
  tr <- ccc_trends(if(fixture=="original") y_state~x else ipt~x+x2,d,"group","year","gvar")
  write.csv(tr$series,paste0("artifacts/r_",fixture,"_series.csv"),row.names=FALSE,na="")
  write.csv(tr$pairs,paste0("artifacts/r_",fixture,"_pairs.csv"),row.names=FALSE,na="")
  png(paste0("artifacts/r_",fixture,".png"),width=1800,height=1100,res=140)
  plot(tr,panels="all"); dev.off()
}
cat("R cross-language exports completed\n")
