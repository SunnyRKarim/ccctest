"""Run from repository root after installing ccctest[plot]."""
from pathlib import Path
import pandas as pd
from ccctest import ccc_test,ccc_trends
root=Path(__file__).resolve().parents[2]
out=root/'artifacts';out.mkdir(exist_ok=True)
d=pd.read_csv(root/'validation/fixtures/original.csv')
d['category']=d.id%3;d['x_squared']=d.x**2
fit=ccc_test(d,'y_state',['x','category','x_squared'],group='group',time='year',cohort='gvar',categorical=['category'],alltests=True)
print(fit)
fit.tests.to_csv(out/'python_tests.csv')
demo=pd.read_csv(root/'validation/fixtures/plots.csv')
tr=ccc_trends(demo,'ipt',['x','x2'],group='group',time='year',cohort='gvar',matches={1:{2:.5,3:.5}})
tr.series.to_csv(out/'python_trends.csv',index=False)
tr.pairs.to_csv(out/'python_pairs.csv',index=False)
tr.plot('all').savefig(out/'python_demo.png',dpi=180)
