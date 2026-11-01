.prepare <- function(formula, data, group, time, cohort=NULL, untreated=NULL, subset=NULL) {
  if (is.null(cohort) && is.null(untreated)) stop("Specify cohort (0=never) or untreated")
  if (is.null(subset)) subset <- rep(TRUE,nrow(data))
  if (!is.logical(subset) || length(subset)!=nrow(data) || anyNA(subset)) stop("subset must be a complete logical mask")
  if (!is.numeric(data[[time]])) stop("time must be ordered numeric dates in a declared unit")
  if (any(is.infinite(data[[time]]))) stop("Infinite time")
  if (!is.null(cohort)) {
    g <- data[[cohort]]
    if (!is.numeric(g) || any(is.infinite(g))) stop("Invalid numeric cohort")
    if (any(data[[time]][subset]==0,na.rm=TRUE)) stop("time=0 conflicts with never-treated code")
    if (any(vapply(split(g,data[[group]]),function(x) length(unique(x[!is.na(x)]))>1,logical(1)))) stop("Cohort must be constant within policy region")
    eligible <- !is.na(g) & (g==0 | data[[time]]<g)
  }
  if (!is.null(untreated)) {
    a <- data[[untreated]]
    if (any(!is.na(a) & !a %in% c(0,1))) stop("untreated must be 0/1/missing")
    key <- interaction(data[[group]],data[[time]],drop=TRUE)
    if (any(vapply(split(a,key),function(x) length(unique(x[!is.na(x)]))>1,logical(1)))) stop("Status varies within cell")
    for (idx in split(seq_len(nrow(data)),data[[group]])) {
      idx <- idx[order(data[[time]][idx])]
      if (any(diff(a[idx][!is.na(a[idx])])>0)) stop("Treatment reversal unsupported")
    }
    if (!is.null(cohort)) {
      known <- !is.na(g) & !is.na(a) & !is.na(data[[time]])
      if (any(eligible[known] != a[known])) stop("Cohort/status disagreement")
      eligible <- eligible & !is.na(a)
    } else eligible <- !is.na(a) & a==1
  }
  eligible[is.na(eligible)] <- FALSE
  mf <- model.frame(formula,data,na.action=na.pass)
  complete <- complete.cases(mf,data[[group]],data[[time]])
  sample <- subset & eligible & complete
  if (!any(sample)) stop("No complete untreated observations")
  # Expand one basis on the common analysis rows, preserving declared factor levels.
  mf <- mf[sample,,drop=FALSE]
  z <- model.matrix(terms(formula),mf)
  z <- z[,colnames(z)!="(Intercept)",drop=FALSE]
  y <- model.response(mf)
  if (!is.numeric(y) || !ncol(z) || any(!is.finite(c(y,z)))) stop("Need finite numeric outcome and nonempty design")
  list(data=data[sample,,drop=FALSE],y=y,z=z,sample=sample,
       diagnostics=list(N_input=nrow(data),N_restricted=sum(subset),N=sum(sample),
         excluded_eligibility=sum(subset & !eligible),excluded_complete_case=sum(subset & eligible & !complete)))
}
.mapping <- function(j,s,t,U,S,T,K,model) {
  L <- switch(model,H=K,R=S*K,T=T*K,TW=U*K,A=(S+T-1)*K)
  M <- matrix(0,K,L)
  block <- switch(model,H=1,R=s,T=t,TW=j,A=s)
  M[,seq_len(K)+(block-1)*K] <- diag(K)
  if (model=="A" && t>1) M[,seq_len(K)+(S+t-2)*K] <- diag(K)
  M
}
.factor <- function(A,label) {
  singular <- svd(A,nu=0,nv=0)$d
  rank <- sum(singular>max(dim(A))*.Machine$double.eps*max(singular))
  condition <- max(singular)/min(singular)
  if (rank<nrow(A) || !is.finite(condition) || condition>1e12) stop(sprintf("%s: rank %d/%d condition %.4g",label,rank,nrow(A),condition))
  list(chol=chol(A),rank=rank,condition=condition)
}
.solve <- function(ch,b) backsolve(ch,forwardsolve(t(ch),b))
.fit <- function(y,z,groups,times,model,vce="HC1") {
  gs <- sort(unique(groups)); ts <- sort(unique(times)); S <- length(gs); T <- length(ts)
  cells <- unique(data.frame(group=groups,time=times)); cells <- cells[order(cells$group,cells$time),]
  U <- nrow(cells); K <- ncol(z); N <- nrow(z)
  L <- switch(model,H=K,R=S*K,T=T*K,TW=U*K,A=(S+T-1)*K); P <- U+L
  if (L>2000) stop("resource_limit: more than 2000 slopes")
  if (N<=P) stop("insufficient residual df")
  XX <- matrix(0,L,L); xy <- numeric(L); chunks <- list(); means <- matrix(NA_real_,U,K+1); counts <- integer(U)
  for (j in seq_len(U)) {
    idx <- groups==cells$group[j] & times==cells$time[j]
    yz <- cbind(y[idx],z[idx,,drop=FALSE]); means[j,] <- colMeans(yz); counts[j] <- sum(idx)
    yz <- sweep(yz,2,means[j,]); X <- yz[,-1,drop=FALSE]; cy <- yz[,1]
    M <- .mapping(j,match(cells$group[j],gs),match(cells$time[j],ts),U,S,T,K,model)
    XX <- XX+t(M)%*%crossprod(X)%*%M; xy <- xy+t(M)%*%crossprod(X,cy)
    chunks[[j]] <- list(X=X,y=cy,M=M)
  }
  fac <- .factor(XX,"centered slope design"); beta <- as.vector(.solve(fac$chol,xy)); B <- chol2inv(fac$chol)
  meat <- matrix(0,L,L); sse <- 0; slopes <- matrix(NA_real_,U,K)
  for (j in seq_len(U)) {
    a <- chunks[[j]]; slopes[j,] <- a$M%*%beta; e <- as.vector(a$y-a$X%*%slopes[j,])
    sse <- sse+sum(e^2); meat <- meat+t(a$M)%*%crossprod(a$X*e)%*%a$M
  }
  V <- if (vce=="OLS") B*sse/(N-P) else N/(N-P)*B%*%meat%*%B
  list(beta=beta,covariance=V,intercepts=means[,1]-rowSums(means[,-1,drop=FALSE]*slopes),slopes=slopes,
       means=means,cells=cells,counts=counts,n=N,parameters=P,rank=fac$rank,condition=fac$condition)
}
.equal <- function(count,K,L) {
  R <- matrix(0,(count-1)*K,L)
  for (j in 2:count) {
    R[(seq_len(K)+(j-2)*K),seq_len(K)] <- -diag(K)
    R[(seq_len(K)+(j-2)*K),seq_len(K)+(j-1)*K] <- diag(K)
  }
  R
}
.wald <- function(f,R) {
  delta <- R%*%f$beta; C <- R%*%f$covariance%*%t(R)
  fac <- .factor(C,"restriction covariance"); W <- as.numeric(crossprod(delta,.solve(fac$chol,delta)))
  if (!is.finite(W) || W<0) stop("Nonfinite/negative Wald statistic")
  c(W=W,Q=nrow(R),p=pchisq(W,nrow(R),lower.tail=FALSE))
}
.select <- function(p1,pr,pt,alpha) {
  if (!is.finite(p1) || p1<0 || p1>1) return(c("undetermined","stage1_failure"))
  if (p1>alpha) return(c("homogeneous","stage1_nonrejection"))
  if (any(!is.finite(c(pr,pt))) || any(c(pr,pt)<0 | c(pr,pt)>1)) return(c("undetermined","stage2_failure"))
  h <- p.adjust(c(pr,pt),"holm")<=alpha
  if (h[1] && !h[2]) return(c("region","holm_region_only"))
  if (h[2] && !h[1]) return(c("time","holm_time_only"))
  c("twoway",if(all(h)) "holm_both" else "holm_neither")
}

ccctest <- function(formula,data,group,time,cohort=NULL,untreated=NULL,vce="HC1",alpha=.05,alltests=FALSE,subset=NULL) {
  vce <- toupper(vce); if(vce=="HOMOSKEDASTIC") vce <- "OLS"
  if (!vce %in% c("HC1","OLS")) stop("Only unweighted HC1/OLS; cluster/survey CCC inference unsupported")
  if (length(alpha)!=1 || !is.finite(alpha) || alpha<=0 || alpha>=1) stop("alpha must be in (0,1)")
  a <- .prepare(formula,data,group,time,cohort,untreated,subset)
  g <- a$data[[group]]; t <- a$data[[time]]; U <- nrow(unique(data.frame(g,t))); S <- length(unique(g)); T <- length(unique(t)); K <- ncol(a$z)
  if (min(S,T)<2) stop("Need two untreated regions and periods")
  tests <- matrix(NA_real_,3,7,dimnames=list(c("omnibus","region","time"),c("W","Q","p","p_holm","reject","performed","used")))
  tests[,"Q"] <- c(K*(U-1),K*(S-1),K*(T-1)); tests[,6:7] <- 0
  fits <- restrictions <- errors <- restriction_ranks <- list()
  for(stage in 1:2) {
    p1 <- tests[1,"p"]
    if(stage==2 && (!is.finite(p1) || (p1>alpha && !alltests))) break
    ids <- if(stage==1) 1 else 2:3; tests[ids,"performed"] <- 1; tests[ids,"used"] <- as.numeric(stage==1 || p1<=alpha)
    name <- paste0("stage",stage)
    f <- tryCatch(.fit(a$y,a$z,g,t,if(stage==1) "TW" else "A",vce),error=function(e)e)
    if(inherits(f,"error")) { errors[[name]] <- conditionMessage(f); next }
    fits[[name]] <- f
    if(stage==1) restrictions$omnibus <- .equal(U,K,length(f$beta)) else {
      restrictions$region <- .equal(S,K,length(f$beta)); restrictions$time <- cbind(matrix(0,K*(T-1),S*K),diag(K*(T-1)))
    }
    for(i in ids) {
      h <- rownames(tests)[i]
      R <- restrictions[[h]]; C <- R%*%f$covariance%*%t(R)
      singular <- svd(C,nu=0,nv=0)$d
      restriction_ranks[[h]] <- sum(singular>max(dim(C))*.Machine$double.eps*max(singular))
      ans <- tryCatch(.wald(f,restrictions[[h]]),error=function(e)e)
      if(inherits(ans,"error")) errors[[h]] <- conditionMessage(ans) else tests[i,1:3] <- ans
    }
  }
  if(is.finite(tests[1,"p"])) tests[1,"reject"] <- as.numeric(tests[1,"p"]<=alpha)
  if(all(is.finite(tests[2:3,"p"]))) {
    tests[2:3,"p_holm"] <- p.adjust(tests[2:3,"p"],"holm"); tests[2:3,"reject"] <- as.numeric(tests[2:3,"p_holm"]<=alpha)
  }
  chosen <- .select(tests[1,"p"],tests[2,"p"],tests[3,"p"],alpha)
  structure(list(tests=as.data.frame(tests),selected=chosen[1],reason=chosen[2],status=if(chosen[1]=="undetermined") "undetermined" else "ok",
    sample=a$sample,basis=colnames(a$z),fits=fits,restrictions=restrictions,
    diagnostics=c(a$diagnostics,list(U=U,S=S,T=T,K=K,P1=U*(K+1),P2=U+K*(S+T-1),vce=vce,alpha=alpha,errors=errors,restriction_ranks=restriction_ranks))),class="ccctest")
}
print.ccctest <- function(x,...) { cat("CCC selected specification:",x$selected,"(",x$reason,")\n"); print(x$tests,...); invisible(x) }
summary.ccctest <- function(object,...) object
test_table <- function(x) x$tests
selection <- function(x) x$selected
