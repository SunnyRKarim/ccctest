ccc_trends <- function(formula,data,group,time,cohort,subset=NULL,focal=NULL,window=NULL,
                       controls="never",matches=NULL,focal_weights=NULL,reference="zero") {
  a <- .prepare(formula,data,group,time,cohort,subset=subset)
  d <- a$data; z <- a$z; y <- a$y; gs <- tapply(d[[cohort]],d[[group]],function(x)x[1])
  if(is.null(focal)) focal <- names(gs)[gs!=0]
  focal <- as.character(focal)
  if(!length(focal) || anyDuplicated(focal) || any(!focal %in% names(gs)) || any(gs[focal]==0)) stop("Invalid focal adopters")
  first <- min(gs[focal]); mask <- d[[time]]<first
  if(!is.null(window)) {
    if(length(window)!=2 || window[1]>window[2] || window[2]>=first) stop("Invalid pretreatment window")
    mask <- mask & d[[time]]>=window[1] & d[[time]]<=window[2]
  }
  dates <- sort(unique(d[[time]][mask])); if(length(dates)<2) stop("Need two pretreatment dates")
  if(!controls %in% c("never","notyet")) stop("Unknown controls option")
  eligible <- setdiff(names(gs)[gs==0 | (controls=="notyet" & gs>max(dates))],focal)
  if(!length(eligible)) stop("No fixed eligible controls")
  if(is.null(focal_weights)) focal_weights <- setNames(rep(1/length(focal),length(focal)),focal)
  valid <- function(x) length(x)>0 && all(is.finite(x)) && all(x>=0) && abs(sum(x)-1)<1e-10
  if(!setequal(names(focal_weights),focal) || !valid(focal_weights)) stop("Invalid focal weights")
  if(is.null(matches)) matches <- do.call(rbind,lapply(focal,function(g) data.frame(focal=g,control=eligible,control_weight=1/length(eligible))))
  matches$focal <- as.character(matches$focal); matches$control <- as.character(matches$control)
  if(!setequal(unique(matches$focal),focal) || any(!matches$control %in% eligible) || any(matches$focal==matches$control) || anyDuplicated(matches[,c("focal","control")])) stop("Invalid/duplicate/self matches")
  if(!all(vapply(split(matches$control_weight,matches$focal),valid,logical(1)))) stop("Invalid comparison weights")
  matches$focal_weight <- unname(focal_weights[matches$focal])
  used <- union(focal,matches$control); mask <- mask & as.character(d[[group]]) %in% used
  d <- d[mask,,drop=FALSE]; z <- z[mask,,drop=FALSE]; y <- y[mask]; g <- d[[group]]; t <- d[[time]]
  if(nrow(unique(data.frame(g,t)))!=length(used)*length(dates)) stop("Missing endpoint cell in fixed comparison set")
  K <- ncol(z)
  if(is.character(reference)) {
    if(!reference %in% c("zero","pooled")) stop("reference must be zero, pooled or a K-vector")
    zr <- if(reference=="zero") rep(0,K) else colMeans(z)
  } else zr <- reference
  if(length(zr)!=K || any(!is.finite(zr))) stop("Invalid reference vector")
  fits <- lapply(c("H","R","T","TW"),function(m).fit(y,z,g,t,m,"OLS")); names(fits) <- c("H","R","T","TW")
  f <- fits$TW; U <- nrow(f$cells)
  idx <- function(s,tt) which(as.character(f$cells$group)==s & f$cells$time==tt)
  cells <- cbind(f$cells,n=f$counts,mean_y=f$means[,1],as.data.frame(f$means[,-1,drop=FALSE]))
  names(cells)[seq_len(K)+4] <- paste0("mu",seq_len(K))
  ranges <- lapply(seq_len(U),function(j) apply(z[g==f$cells$group[j] & t==f$cells$time[j],,drop=FALSE],2,range))
  namespanels <- c("raw","homogeneous","region","time","twoway")
  series <- coefficients <- pairs <- list()
  for(m in 1:5) {
    values <- if(m==1) f$means[,1] else fits[[m-1]]$intercepts+as.vector(fits[[m-1]]$slopes%*%zr)
    if(m>1) {
      co <- cbind(model=namespanels[m],f$cells,theta=fits[[m-1]]$intercepts,as.data.frame(fits[[m-1]]$slopes))
      names(co)[seq_len(K)+4] <- paste0("beta",seq_len(K)); coefficients[[length(coefficients)+1]] <- co
    }
    for(tt in dates) {
      tr <- sum(vapply(focal,function(s) focal_weights[s]*values[idx(s,tt)],numeric(1)))
      cr <- sum(vapply(seq_len(nrow(matches)),function(j) matches$focal_weight[j]*matches$control_weight[j]*values[idx(matches$control[j],tt)],numeric(1)))
      series[[length(series)+1]] <- data.frame(panel=namespanels[m],time=tt,baseline=NA_real_,treated=tr,control=cr,gap=tr-cr)
    }
  }
  for(h in 2:length(dates)) {
    tt <- dates[h]; b <- dates[h-1]; tr <- cr <- 0
    for(j in seq_len(nrow(matches))) {
      s <- matches$focal[j]; c <- matches$control[j]; ids <- c(idx(s,tt),idx(s,b),idx(c,tt),idx(c,b)); mu <- f$means[ids[1],-1]
      pred <- f$intercepts[ids]+as.vector(f$slopes[ids,,drop=FALSE]%*%mu)
      row <- data.frame(focal=s,control=c,time=tt,baseline=b,focal_weight=matches$focal_weight[j],control_weight=matches$control_weight[j],pred_st=pred[1],pred_sb=pred[2],pred_ct=pred[3],pred_cb=pred[4],delta_t=pred[1]-pred[2],delta_c=pred[3]-pred[4])
      for(k in seq_len(K)) row[[paste0("mu",k)]] <- mu[k]
      for(q in 1:4) {
        label <- c("st","sb","ct","cb")[q]; row[[paste0("theta_",label)]] <- f$intercepts[ids[q]]
        for(k in seq_len(K)) row[[paste0("beta_",label,k)]] <- f$slopes[ids[q],k]
        row[[paste0("outside_",label)]] <- any(ranges[[ids[1]]][1,]<ranges[[ids[q]]][1,]) || any(ranges[[ids[1]]][2,]>ranges[[ids[q]]][2,])
      }
      pairs[[length(pairs)+1]] <- row
      w <- row$focal_weight*row$control_weight; tr <- tr+w*row$delta_t; cr <- cr+w*row$delta_c
    }
    series[[length(series)+1]] <- data.frame(panel="integrated",time=tt,baseline=b,treated=tr,control=cr,gap=tr-cr)
  }
  structure(list(series=do.call(rbind,series),pairs=do.call(rbind,pairs),cells=cells,coefficients=do.call(rbind,coefficients),matches=matches,reference=zr,
    diagnostics=list(N_test_eligible=a$diagnostics$N,N_plot=nrow(d),basis=colnames(z),window=range(dates),intervals=diff(dates))),class="ccc_trends")
}
plot_data <- function(x) x$series
print.ccc_trends <- function(x,...) { print(x$series,...); invisible(x) }
plot.ccc_trends <- function(x,panels="core",...) {
  all <- c("raw","homogeneous","region","time","twoway","integrated")
  names <- if(panels=="all") all else if(panels=="core") all[c(1,2,6)] else panels
  if(any(!names %in% all)) stop("Unknown panel")
  old <- graphics::par(no.readonly=TRUE); on.exit(graphics::par(old))
  graphics::par(mfrow=c(ceiling(length(names)/3),min(3,length(names))),mar=c(4,4,3,1))
  grDevices::dev.control(displaylist="enable")
  for(name in names) {
    d <- x$series[x$series$panel==name,]
    graphics::matplot(d$time,cbind(d$treated,d$control),type="b",pch=c(16,17),lty=c(1,2),col=c("#2367a3","#b64452"),xlab="Period",ylab=if(name=="integrated") "Outcome change" else "Outcome level",main=name,...)
    graphics::legend("topleft",legend=c("Treated","Control"),col=c("#2367a3","#b64452"),lty=c(1,2),bty="n",cex=.8)
  }
  invisible(grDevices::recordPlot())
}
