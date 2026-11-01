mata:
real scalar ccc_trends_loaded() return(1)
void ccc_trends_run(string scalar vars, string scalar use, string scalar ref, string scalar matchname)
{
    real matrix D, base, series, pairs, coefs, maps, limits, M, audit
    real colvector times, gs, focal, control, ii, tt, cc, bb, dd
    real rowvector zref, mu, pred, outside
    real scalar U,K,S,T,j,m,s,c,t,b,h,q,nt,nc,w,aw,prev,N,idx
    string rowvector models
    struct ccc_fit scalar f
    D=st_data(.,tokens(vars),use)
    // Last columns: original date and cohort. Remaining columns are s,t,y,z.
    times=uniqrows(sort(D[.,cols(D)-1],1)); gs=J(max(D[.,1]),1,.)
    for (s=1;s<=rows(gs);s++) gs[s]=D[selectindex(D[.,1]:==s)[1],cols(D)]
    D=D[.,1..cols(D)-2]; K=cols(D)-3; S=max(D[.,1]); T=rows(times)
    focal=selectindex(gs:!=0); control=selectindex(gs:==0)
    nt=rows(focal); nc=rows(control)
    if (nt==0 | nc==0 | T<2) {
        st_local("plot_error","Need focal adopters, never-treated controls and two common preperiods")
        return
    }
    if (matchname=="") {
        maps=J(0,4,.)
        for (s=1;s<=nt;s++) for (c=1;c<=nc;c++) maps=maps\(focal[s],control[c],1/nt,1/nc)
    }
    else maps=st_matrix(matchname)
    if (cols(maps)!=4 | hasmissing(maps) | any(maps[.,3..4]:<0)) {
        st_local("plot_error","matchmatrix must contain focal code, control code, focal weight, control weight")
        return
    }
    aw=0
    for (s=1;s<=nt;s++) {
        M=select(maps,maps[.,1]:==focal[s])
        if (rows(M)==0 | abs(sum(M[.,4])-1)>1e-10 | max(M[.,3])!=min(M[.,3])) {
            st_local("plot_error","Every focal region needs fixed normalized matches and a constant focal weight")
            return
        }
        aw=aw+M[1,3]
    }
    if (abs(aw-1)>1e-10 | rows(uniqrows(maps[.,1..2]))!=rows(maps)) {
        st_local("plot_error","Focal weights must sum to one and pairs must be unique")
        return
    }
    for (j=1;j<=rows(maps);j++) {
        if (!any(focal:==maps[j,1]) | !any(control:==maps[j,2]) | maps[j,1]==maps[j,2]) {
            st_local("plot_error","Invalid focal/control code or self match")
            return
        }
    }
    U=rows(uniqrows(sort(D[.,1..2],(1,2))))
    if (U!=S*T) {
        st_local("plot_error","Missing endpoint cell: fixed comparison set requires common support")
        return
    }
    zref=J(1,K,0)
    if (ref=="pooled") zref=mean(D[.,4..cols(D)])
    else if (ref!="zero") zref=st_matrix(ref)
    if (rows(zref)!=1 | cols(zref)!=K | hasmissing(zref)) {
        st_local("plot_error","Reference must be zero, pooled, or a 1 by K matrix")
        return
    }
    models=("H","R","T","TW")
    series=J(T*5+T-1,6,.); coefs=J(0,4+K,.)
    for (m=1;m<=4;m++) {
        f=ccc_fitmodel(D,models[m],"ols")
        if (!f.valid) {
            st_local("plot_error","Requested adjustment unidentified: "+models[m]+" "+f.reason)
            return
        }
        coefs=coefs\(J(U,1,m),f.cells[.,1..2],f.theta,f.slopes)
        if (m==1) {
            base=f.cells,f.means
            limits=J(U,2*K,.)
            for (j=1;j<=U;j++) {
                M=select(D[.,4..cols(D)],(D[.,1]:==base[j,1]):&(D[.,2]:==base[j,2]))
                limits[j,.]=colmin(M),colmax(M)
            }
        }
        for (t=1;t<=T;t++) {
            pred=J(1,2,0); outside=J(1,2,0)
            for (j=1;j<=rows(maps);j++) {
                s=maps[j,1]; c=maps[j,2]; w=maps[j,3]*maps[j,4]
                ii=selectindex((base[.,1]:==s):&(base[.,2]:==t))
                cc=selectindex((base[.,1]:==c):&(base[.,2]:==t))
                pred=pred+w*(f.theta[ii]+f.slopes[ii,.]*zref',f.theta[cc]+f.slopes[cc,.]*zref')
                outside=outside+w*(base[ii,4],base[cc,4])
            }
            series[m*T+t,.]=(m+1,times[t],.,pred,pred[1]-pred[2])
            if (m==1) series[t,.]=(1,times[t],.,outside,outside[1]-outside[2])
        }
    }
    // f now contains unrestricted cell coefficients. All endpoints use target mu.
    pairs=J(0,20+5*K,.)
    for (t=2;t<=T;t++) {
        pred=J(1,2,0); b=t-1
        for (j=1;j<=rows(maps);j++) {
            s=maps[j,1]; c=maps[j,2]; w=maps[j,3]*maps[j,4]
            ii=selectindex((base[.,1]:==s):&(base[.,2]:==t))
            bb=selectindex((base[.,1]:==s):&(base[.,2]:==b))
            cc=selectindex((base[.,1]:==c):&(base[.,2]:==t))
            dd=selectindex((base[.,1]:==c):&(base[.,2]:==b))
            mu=base[ii,5..cols(base)]
            M=(f.theta[ii],f.slopes[ii,.])\(f.theta[bb],f.slopes[bb,.])\(f.theta[cc],f.slopes[cc,.])\(f.theta[dd],f.slopes[dd,.])
            tt=(ii\bb\cc\dd); outside=J(1,4,0)
            for (h=1;h<=4;h++) outside[h]=any(limits[ii,1..K]:<limits[tt[h],1..K]) | any(limits[ii,K+1..2*K]:>limits[tt[h],K+1..2*K])
            audit=(M*(1,mu)')'
            pairs=pairs\(s,c,times[t],times[b],maps[j,3..4],audit,audit[1]-audit[2],audit[3]-audit[4],mu,vec(M')',outside)
            pred=pred+w*(audit[1]-audit[2],audit[3]-audit[4])
        }
        series[5*T+t-1,.]=(6,times[t],times[b],pred,pred[1]-pred[2])
    }
    st_matrix(st_local("series"),series); st_matrix(st_local("pairs"),pairs)
    st_matrix(st_local("coefs"),coefs); st_matrix(st_local("cellmeans"),base)
    st_matrix(st_local("refmat"),zref); st_matrix(st_local("matches"),maps)
    st_local("plot_N",strofreal(rows(D)))
}
end
