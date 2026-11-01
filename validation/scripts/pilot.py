"""Small configurable/resumable selection pilot; no ATT or full Monte Carlo."""
import argparse,json,math
from pathlib import Path
import numpy as np
import pandas as pd
from ccctest import ccc_test
parser=argparse.ArgumentParser()
parser.add_argument('--reps',type=int,default=20)
parser.add_argument('--n-cell',type=int,default=50)
parser.add_argument('--vce',choices=['HC1','OLS'],default='HC1')
parser.add_argument('--heteroskedastic',action='store_true')
parser.add_argument('--output',default='artifacts/pilot.csv')
args=parser.parse_args()
if args.reps<1 or args.reps>1000 or args.n_cell<5: parser.error('Require 1..1000 reps and n-cell >= 5; larger runs need an explicit reviewed configuration')
path=Path(args.output);path.parent.mkdir(parents=True,exist_ok=True)
rows=pd.read_csv(path).to_dict('records') if path.exists() else []
key=(args.n_cell,args.vce,args.heteroskedastic)
done={(int(r['rep']),r['outcome']) for r in rows if (int(r['n_cell']),r['vce'],bool(r['heteroskedastic']))==key}
for rep in range(1,args.reps+1):
    rng=np.random.default_rng(args.n_cell*100000+rep)
    g=np.repeat(np.repeat(np.arange(1,7),args.n_cell),6);t=np.tile(np.arange(1,7),6*args.n_cell)
    a=np.array([.5,.9,1.5,1.1,.7,1.3])[g-1];b=np.array([.5,1.3,.9,1.5,.7,1.1])[t-1]
    sigma=5 if not args.heteroskedastic else np.array([3,4,5,6,7,5])[g-1]
    base=3*g+t+rng.normal(size=len(g))*sigma
    x=np.where(g==5,-1.25*b,np.where(g==6,1.25*b,0))+rng.normal(size=len(g))*2
    d=pd.DataFrame(dict(group=g,year=t,gvar=np.array([3,3,5,5,0,0])[g-1],x=x))
    for outcome,slope in [('homogeneous',1),('region',a),('time',b),('twoway',a*b)]:
        if (rep,outcome) in done: continue
        d['y']=base+x*slope
        f=ccc_test(d,'y',['x'],group='group',time='year',cohort='gvar',vce=args.vce)
        rows.append(dict(rep=rep,seed=args.n_cell*100000+rep,n_cell=args.n_cell,vce=args.vce,heteroskedastic=args.heteroskedastic,outcome=outcome,selected=f.selected,status=f.status,stage1_p=f.tests.loc['omnibus','p']))
    pd.DataFrame(rows).to_csv(path,index=False)
    print(f'{rep}/{args.reps} complete',flush=True)
result=pd.DataFrame(rows);report=[]
for outcome,a in result.groupby('outcome'):
    valid=a.status=='ok'; correct=(a.selected==outcome)&valid;n=int(valid.sum());p=float(correct.sum()/n) if n else None
    report.append(dict(outcome=outcome,replications=len(a),failures=int((~valid).sum()),correct_fraction=p,mc_standard_error=math.sqrt(p*(1-p)/n) if n else None))
path.with_suffix('.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
