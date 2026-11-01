"""Independent dense regressions and direct observation-level adjustments."""
import numpy as np
import pandas as pd

def dense_trends(d,outcome,covariates,reference):
    d=d.loc[d.year<d.loc[d.gvar!=0,'gvar'].min()].copy()
    cells=sorted(set(zip(d.group,d.year)));gs=sorted(d.group.unique());ts=sorted(d.year.unique())
    y=d[outcome].to_numpy();z=d[covariates].to_numpy();k=len(covariates)
    ci=np.array([cells.index(c) for c in zip(d.group,d.year)])
    intercept=np.eye(len(cells))[ci];values={}
    for model in ['H','R','T','TW']:
        codes=np.zeros(len(d),int) if model=='H' else np.array([gs.index(g) for g in d.group]) if model=='R' else np.array([ts.index(t) for t in d.year]) if model=='T' else ci
        count=codes.max()+1
        design=np.column_stack([intercept,*(z*(codes==c)[:,None] for c in range(count))])
        q,r=np.linalg.qr(design,mode='reduced');b=np.linalg.solve(r,q.T@y)
        slopes=b[len(cells):].reshape(count,k)
        adjusted=y-np.sum((z-reference)*slopes[codes],axis=1)
        values[model]=np.array([adjusted[ci==j].mean() for j in range(len(cells))])
    return cells,values
