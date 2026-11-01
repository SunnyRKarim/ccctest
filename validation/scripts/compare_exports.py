from pathlib import Path
import json
import numpy as np
import pandas as pd
from ccctest import ccc_test,ccc_trends
root=Path(__file__).resolve().parents[2]
checks=[]
def compare(name,a,b,atol=1e-8):
    a=np.asarray(a,dtype=float);b=np.asarray(b,dtype=float)
    np.testing.assert_allclose(a,b,rtol=1e-8,atol=atol,equal_nan=True,err_msg=name)
    checks.append(dict(name=name,max_absolute_difference=float(np.nanmax(abs(a-b)))))
for fixture in ['original','unbalanced']:
    d=pd.read_csv(root/f'validation/fixtures/{fixture}.csv')
    out,cov=('y_state',['x']) if fixture=='original' else ('y',['x','z'])
    for vce in ['HC1','OLS']:
        f=ccc_test(d,out,cov,group='group',time='year',cohort='gvar',vce=vce,alltests=True)
        for lang in ['stata','r']:
            prefix=root/f'artifacts/{lang}_{fixture}_{vce}_'
            read=lambda name: pd.read_csv(str(prefix)+name+'.csv',header=None).to_numpy()
            native=read('tests')
            compare(f'{lang} {fixture} {vce} tests',native,f.tests)
            compare(f'{lang} {fixture} {vce} p-values',native[:,2:4],f.tests[['p','p_holm']],1e-12)
            compare(f'{lang} {fixture} {vce} sample mask',read('mask').ravel(),f.sample,0)
            for file,name in zip(['R1','R_region','R_time'],['omnibus','region','time']):
                compare(f'{lang} {fixture} {vce} {name} restrictions',read(file),f.restrictions[name],0)
            for stage in [1,2]:
                a=f.fits[f'stage{stage}']
                compare(f'{lang} {fixture} {vce} b{stage}',read(f'b{stage}'),a.beta[None,:])
                compare(f'{lang} {fixture} {vce} V{stage}',read(f'V{stage}'),a.covariance)
                compare(f'{lang} {fixture} {vce} theta{stage}',read(f'theta{stage}').ravel(),a.intercepts)
for fixture in ['original','plots']:
    d=pd.read_csv(root/f'validation/fixtures/{fixture}.csv')
    out,cov=('y_state',['x']) if fixture=='original' else ('ipt',['x','x2'])
    tr=ccc_trends(d,out,cov,group='group',time='year',cohort='gvar')
    tr.plot('all').savefig(root/f'artifacts/python_{fixture}.png',dpi=160)
    for lang in ['stata','r']:
        series=pd.read_csv(root/f'artifacts/{lang}_{fixture}_series.csv')
        compare(f'{lang} {fixture} plot series',series.drop(columns='panel'),tr.series.drop(columns='panel'))
        pairs=pd.read_csv(root/f'artifacts/{lang}_{fixture}_pairs.csv')
        compare(f'{lang} {fixture} all pair data',pairs[tr.pairs.columns],tr.pairs)
(root/'validation/expected/cross_language_report.json').write_text(json.dumps(checks,indent=2))
print(f'{len(checks)} cross-language arrays passed; max absolute difference {max(x["max_absolute_difference"] for x in checks):.3g}')
