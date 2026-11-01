from pathlib import Path
import hashlib,json,sys
import numpy as np
import pandas as pd
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'reference'))
from dense import reference
root=Path(__file__).resolve().parents[2]
rng=np.random.default_rng(91327)
rows=[]
for s in range(1,5):
    for t in [2,5,9,12]:
        if (s,t)==(2,9): continue
        n=23+3*s+t
        x=rng.normal(size=n); z=rng.normal(size=n)
        y=3*s+t+(.2*s+.1*t)*x+(.7-.1*s)*z+rng.normal(size=n)*(1+.1*x*x)
        for j in range(n): rows.append((s,t,20 if s<=2 else 0,x[j],z[j],y[j]))
d=pd.DataFrame(rows,columns=['group','year','gvar','x','z','y'])
d.to_csv(root/'validation/fixtures/unbalanced.csv',index=False,float_format='%.17g')
for vce in ['HC1','OLS']:
    result=reference(d,'y',['x','z'],vce)
    np.savez(root/f'validation/expected/unbalanced_{vce}.npz',**result)
# Deliberate eight-period demonstration extension; not the original six-period DGP.
grid=np.tile(np.linspace(-2,2,9),5)
rows=[]
for s in [1,2,3]:
    theta=10*s
    for t in range(1,9):
        mu=.25*t
        x=grid+(mu if s==1 else -.3*s*t)
        z=x*x
        A=np.column_stack([np.ones(len(x)),x,z]); raw=grid**3
        e=raw-A@np.linalg.lstsq(A,raw,rcond=None)[0]
        if t>1: theta+=2+mu if s==1 else 2 if s==2 else 2-mu
        beta=s*t
        ordinary=10*s+2*t+grid+.1*e
        cpt=10*s+2*t+3*x+.5*z+.1*e
        ipt=theta+beta*x+.2*z+.1*e
        for j in range(len(x)): rows.append((s,t,10 if s==1 else 0,x[j],z[j],grid[j],ordinary[j],cpt[j],ipt[j]))
p=pd.DataFrame(rows,columns=['group','year','gvar','x','x2','fixed_x','ordinary','cpt','ipt'])
for dest in ['validation/fixtures/plots.csv','stata/examples/plots.csv','r/inst/extdata/plots.csv']:
    p.to_csv(root/dest,index=False,float_format='%.17g')
metadata={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'validation/fixtures').glob('*.csv')}
(root/'validation/fixtures/checksums.json').write_text(json.dumps(metadata,indent=2))
print('Unbalanced K=2 fixture and algebraically specified eight-period plots saved')
