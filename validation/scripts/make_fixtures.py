"""AST-extract audited definitions only; no notebook statements or ATT calls."""
from pathlib import Path
import ast, hashlib, json, sys
import numpy as np
import pandas as pd
import statsmodels.api as sm
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'reference'))
from dense import reference
root=Path(__file__).resolve().parents[2]
source=root/'Third Chapter Stage2 Sim.py'
assert hashlib.sha256(source.read_bytes()).hexdigest()=='dbf52b83d2daf02a37b0e93b8cb4775ad8603c427bdf915581892212336f1fea'
names={'generate_dgp','safe_wald_test','cell_intercept_matrix','ccc_wald_tests','holm_two_tests','choose_model_from_tests'}
tree=ast.parse(source.read_text())
module=ast.Module(body=[x for x in tree.body if isinstance(x,ast.FunctionDef) and x.name in names],type_ignores=[])
env=dict(np=np,pd=pd,sm=sm,G=6,T=6,sigma_y=5,sigma_x=2,alpha=.05,state_coef=np.array([.5,.9,1.5,1.1,.7,1.3]),time_coef=np.array([.5,1.3,.9,1.5,.7,1.1]),treatment_time={1:3,2:3,3:5,4:5,5:np.inf,6:np.inf},gvar_map={1:3,2:3,3:5,4:5,5:0,6:0})
exec(compile(module,str(source),'exec'),env)
d=env['generate_dgp'](50,5000001)
path=root/'validation/fixtures/original.csv'
d.to_csv(path,index=False,float_format='%.17g')
d.to_csv(root/'stata/examples/original.csv',index=False,float_format='%.17g')
rows=[]
for out in ['y_homogeneous','y_state','y_time','y_twoway']:
    for vce in ['HC1','OLS']:
        r=reference(d,out,['x'],vce)
        assert (r['n'],r['u'],len(r['b1']),len(r['b2']))==(1200,24,48,35)
        if vce=='HC1':
            s=env['ccc_wald_tests'](d,out)
            np.testing.assert_allclose(r['tests'][:,0],[s['W_stage1'],s['W_state'],s['W_time']],atol=1e-8,rtol=1e-8)
        np.savez(root/f'validation/expected/{out}_{vce}.npz',**r)
        for name,test in zip(['omnibus','region','time'],r['tests']):
            rows.append(dict(outcome=out,vce=vce,test=name,W=test[0],Q=test[1],p=test[2]))
pd.DataFrame(rows).to_csv(root/'validation/expected/tests.csv',index=False,float_format='%.17g')
metadata=dict(seed=5000001,n_cell=50,N=1800,N_untreated=1200,U=24,P1=48,P2=35,Q=[23,5,5],basis=['x'],never=0,reference_cell=[1,1],reference_period=1,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
(root/'validation/fixtures/original.json').write_text(json.dumps(metadata,indent=2))
print(pd.DataFrame(rows).to_string(index=False))
