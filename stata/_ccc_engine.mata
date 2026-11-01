mata:
struct ccc_fit {

    real scalar valid, n, u, k, p, rank, condition
    string scalar reason
    real colvector b, theta
    real matrix V, means, slopes, cells

}

real matrix ccc_map(real scalar j, real scalar s, real scalar t,
    real scalar U, real scalar S, real scalar T, real scalar K, string scalar model)
{

    real scalar L
    real matrix M
    L = K
    if (model=="TW") L=U*K
    if (model=="R") L=S*K
    if (model=="T") L=T*K
    if (model=="A") L=(S+T-1)*K
    M=J(K,L,0)
    if (model=="H") M=I(K)
    if (model=="TW") M[.,(j-1)*K+1..j*K]=I(K)
    if (model=="R" | model=="A") M[.,(s-1)*K+1..s*K]=I(K)
    if (model=="T") M[.,(t-1)*K+1..t*K]=I(K)
    if (model=="A" & t>1) M[.,(S+t-2)*K+1..(S+t-1)*K]=I(K)
    return(M)

}

struct ccc_fit scalar ccc_fitmodel(real matrix D, string scalar model, string scalar vce)
{

    struct ccc_fit scalar f
    real matrix info, X, Z, M, XX, meat, B, C
    real colvector y, yy, xy, e, ix
    real scalar j, S, T, L, lo, hi, sse
    f.valid=0; f.reason="rank_deficient"; f.rank=.; f.condition=.
    f.n=rows(D); f.k=cols(D)-3
    D=sort(D,(1,2))
    // panelsetup uses one column; construct boundaries for both cell keys.
    ix=selectindex((1 \ (rowsum(D[|2,1\rows(D),2|]:!=D[|1,1\rows(D)-1,2|]):>0)))
    info=(ix,((ix[|2\rows(ix)|]:-1)\rows(D)))
    f.u=rows(info); S=max(D[.,1]); T=max(D[.,2])
    f.cells=J(f.u,3,.)
    for (j=1;j<=f.u;j++) f.cells[j,.]=(D[info[j,1],1],D[info[j,1],2],info[j,2]-info[j,1]+1)
    L=f.k
    if (model=="TW") L=f.u*f.k
    if (model=="R") L=S*f.k
    if (model=="T") L=T*f.k
    if (model=="A") L=(S+T-1)*f.k
    f.p=f.u+L
    if (L>2000) {
 f.reason="resource_limit_2000_slopes"; return(f)
}

    if (f.n<=f.p) {
 f.reason="insufficient_residual_df"; return(f)
}

    XX=J(L,L,0); xy=J(L,1,0); f.means=J(f.u,f.k+1,.)
    for (j=1;j<=f.u;j++) {

        lo=info[j,1]; hi=info[j,2]
        C=D[|lo,3\hi,cols(D)|]; f.means[j,.]=mean(C)
        C=C:-f.means[j,.]; y=C[.,1]; Z=C[.,2..cols(C)]
        f.cells[j,.]=(D[lo,1],D[lo,2],hi-lo+1)
        M=ccc_map(j,D[lo,1],D[lo,2],f.u,S,T,f.k,model)
        XX=XX+M'*quadcross(Z,Z)*M; xy=xy+M'*quadcross(Z,y)

}

    f.rank=rank(XX); f.condition=cond(XX)
    if (f.rank<L | f.condition>1e12 | missing(f.condition)) return(f)
    f.b=cholsolve(XX,xy); B=cholinv(XX)
    if (hasmissing(f.b) | hasmissing(B)) return(f)
    meat=J(L,L,0); sse=0; f.slopes=J(f.u,f.k,.); f.theta=J(f.u,1,.)
    for (j=1;j<=f.u;j++) {

        lo=info[j,1]; hi=info[j,2]
        C=D[|lo,3\hi,cols(D)|]:-f.means[j,.]; y=C[.,1]; Z=C[.,2..cols(C)]
        M=ccc_map(j,D[lo,1],D[lo,2],f.u,S,T,f.k,model)
        f.slopes[j,.]=(M*f.b)'; f.theta[j]=f.means[j,1]-f.means[j,2..cols(f.means)]*M*f.b
        e=y-Z*M*f.b; sse=sse+quadcross(e,e)
        X=Z:*e; meat=meat+M'*quadcross(X,X)*M

}

    if (vce=="ols") f.V=sse/(f.n-f.p)*B
    else f.V=f.n/(f.n-f.p)*B*meat*B
    f.valid=1; f.reason="ok"
    return(f)

}

real matrix ccc_equal(real scalar count, real scalar K, real scalar L)
{

    real scalar j
    real matrix R
    R=J((count-1)*K,L,0)
    for (j=2;j<=count;j++) {

        R[|(j-2)*K+1,1\(j-1)*K,K|]=-I(K)
        R[|(j-2)*K+1,(j-1)*K+1\(j-1)*K,j*K|]=I(K)

}

    return(R)

}

real rowvector ccc_wald(struct ccc_fit scalar f, real matrix R)
{

    real matrix C
    real colvector d
    real scalar W, Q
    Q=rows(R)
    if (!f.valid) return((.,Q,.))
    C=R*f.V*R'; d=R*f.b
    if (rank(C)<Q | cond(C)>1e12 | hasmissing(C)) return((.,Q,.))
    W=(d'*cholsolve(C,d))[1,1]
    if (missing(W) | W<0) return((.,Q,.))
    return((W,Q,chi2tail(Q,W)))

}

real rowvector ccc_holm(real scalar pr, real scalar pt)
{
    real scalar ar,at
    if (missing(pr) | missing(pt) | min((pr,pt))<0 | max((pr,pt))>1) return((.,.))
    ar=min((1,2*pr)); at=min((1,2*pt))
    if (pr<=pt) at=min((1,max((ar,pt))))
    else ar=min((1,max((at,pr))))
    return((ar,at))
}
string rowvector ccc_decision(real scalar p1, real scalar pr, real scalar pt, real scalar alpha)
{
    real rowvector h
    if (missing(p1) | p1<0 | p1>1) return(("undetermined","stage1_failure"))
    if (p1>alpha) return(("homogeneous","stage1_nonrejection"))
    h=ccc_holm(pr,pt)
    if (hasmissing(h)) return(("undetermined","stage2_failure"))
    if (h[1]<=alpha & h[2]>alpha) return(("region","holm_region_only"))
    if (h[2]<=alpha & h[1]>alpha) return(("time","holm_time_only"))
    if (h[1]<=alpha & h[2]<=alpha) return(("twoway","holm_both"))
    return(("twoway","holm_neither"))
}
void ccc_test_run(string scalar vars, string scalar use, string scalar vce, real scalar alpha, real scalar alltests)
{
    real matrix D, tests, R1, RR, RT
    real rowvector h, ranks
    real scalar S,T,K,U,L,reject1
    struct ccc_fit scalar f,g
    string scalar diagnostic
    string rowvector decision
    D=st_data(.,tokens(vars),use); S=max(D[.,1]); T=max(D[.,2]); K=cols(D)-3
    f=ccc_fitmodel(D,"TW",vce); U=f.u
    tests=J(3,7,.); tests[.,6..7]=J(3,2,0); ranks=J(1,3,.)
    tests[.,2]=(K*(U-1)\K*(S-1)\K*(T-1))
    diagnostic=f.reason
    tests[1,6..7]=(1,1)
    if (f.valid) {
        R1=ccc_equal(U,K,U*K)
        ranks[1]=rank(R1*f.V*R1')
        tests[1,1..3]=ccc_wald(f,R1)
    }
    reject1=.
    if (!missing(tests[1,3])) {
        reject1=(tests[1,3]<=alpha); tests[1,5]=reject1
    }
    if (reject1==1 | (alltests & reject1==0)) {
        g=ccc_fitmodel(D,"A",vce); L=K*(S+T-1)
        tests[2..3,6]=J(2,1,1); tests[2..3,7]=J(2,1,reject1)
        diagnostic=g.reason
        if (g.valid) {
            RR=ccc_equal(S,K,L); RT=(J(K*(T-1),S*K,0),I(K*(T-1)))
            ranks[2]=rank(RR*g.V*RR'); ranks[3]=rank(RT*g.V*RT')
            tests[2,1..3]=ccc_wald(g,RR); tests[3,1..3]=ccc_wald(g,RT)
            st_matrix(st_local("b2"),g.b'); st_matrix(st_local("V2"),g.V)
            st_matrix(st_local("theta2"),g.theta)
            st_matrix(st_local("rr"),RR); st_matrix(st_local("rt"),RT)
        }
        h=ccc_holm(tests[2,3],tests[3,3])
        if (!hasmissing(h)) {
            tests[2,4..5]=(h[1],h[1]<=alpha); tests[3,4..5]=(h[2],h[2]<=alpha)
        }
        else if (diagnostic=="ok") diagnostic="singular_restriction_covariance"
        st_local("P2",strofreal(g.p)); st_local("rank2",strofreal(g.rank))
        st_local("condition2",strofreal(g.condition))
    }
    if (f.valid) {
        st_matrix(st_local("b1"),f.b'); st_matrix(st_local("V1"),f.V)
        st_matrix(st_local("theta"),f.theta); st_matrix(st_local("r1"),R1)
    }
    if (f.valid & missing(tests[1,3])) diagnostic="singular_restriction_covariance"
    decision=ccc_decision(tests[1,3],tests[2,3],tests[3,3],alpha)
    st_matrix(st_local("tests"),tests); st_matrix(st_local("cells"),f.cells)
    st_matrix(st_local("restriction_ranks"),ranks)
    st_local("selected",decision[1]); st_local("reason",decision[2]); st_local("diagnostic",diagnostic)
    st_local("U",strofreal(U)); st_local("P1",strofreal(f.p)); st_local("rank1",strofreal(f.rank))
    st_local("condition1",strofreal(f.condition))
}
end
