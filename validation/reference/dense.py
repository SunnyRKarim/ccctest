"""Independent, deliberately dense reference; never imports production code."""
import numpy as np
from scipy.stats import chi2

def reference(data, outcome, covariates, vce="HC1"):
    d = data.loc[(data.gvar == 0) | (data.year < data.gvar)].dropna(subset=[outcome, *covariates])
    cells = sorted(set(zip(d.group, d.year)))
    groups, times = sorted(d.group.unique()), sorted(d.year.unique())
    z, y = d[covariates].to_numpy(), d[outcome].to_numpy()
    n, k = z.shape
    u = len(cells)
    c = np.array([cells.index(x) for x in zip(d.group, d.year)])
    intercept = np.eye(u)[c]
    sat = np.column_stack([intercept, *(z * (c == j)[:, None] for j in range(u))])
    add = np.column_stack([intercept, *(z * (d.group.to_numpy() == g)[:, None] for g in groups), *(z * (d.year.to_numpy() == t)[:, None] for t in times[1:])])
    def fit(a):
        q, r = np.linalg.qr(a, mode="reduced")
        b = np.linalg.solve(r, q.T @ y)
        e = y-a@b
        ri = np.linalg.solve(r, np.eye(r.shape[0]))
        bread = ri @ ri.T
        v = bread*(e@e)/(n-a.shape[1]) if vce == "OLS" else n/(n-a.shape[1])*bread@((a*e[:,None]).T@(a*e[:,None]))@bread
        return b, v
    b1,v1=fit(sat); b2,v2=fit(add)
    r1=np.zeros((k*(u-1),sat.shape[1])); rr=np.zeros((k*(len(groups)-1),add.shape[1])); rt=np.zeros((k*(len(times)-1),add.shape[1]))
    for j in range(1,u):
        r1[(j-1)*k:j*k,u+j*k:u+(j+1)*k]=np.eye(k)
        r1[(j-1)*k:j*k,u:u+k]=-np.eye(k)
    for j in range(1,len(groups)):
        rr[(j-1)*k:j*k,u+j*k:u+(j+1)*k]=np.eye(k)
        rr[(j-1)*k:j*k,u:u+k]=-np.eye(k)
    rt[:,u+k*len(groups):]=np.eye(rt.shape[0])
    tests=[]
    for b,v,r in [(b1,v1,r1),(b2,v2,rr),(b2,v2,rt)]:
        rb=r@b; w=float(rb@np.linalg.solve(r@v@r.T,rb))
        tests.append([w,len(r),chi2.sf(w,len(r))])
    return dict(tests=np.array(tests),b1=b1,v1=v1,b2=b2,v2=v2,r1=r1,rr=rr,rt=rt,n=n,u=u)
