"""Measured performance; peak RSS sampled at 10ms (not an allocation oracle)."""
import json,platform,time,threading,os
from pathlib import Path
import numpy as np
import pandas as pd
import psutil
from ccctest import ccc_test
root=Path(__file__).resolve().parents[2]
rows=[]
for ncell in [50,5000,30000]:
    rng=np.random.default_rng(993+ncell)
    g=np.repeat(np.arange(1,7),6*ncell);t=np.tile(np.repeat(np.arange(1,7),ncell),6)
    cohort=np.array([3,3,5,5,0,0])[g-1];x=rng.normal(size=len(g));y=3*g+t+(g*.3+t*.2)*x+rng.normal(size=len(g))
    d=pd.DataFrame(dict(group=g,year=t,gvar=cohort,x=x,y=y))
    proc=psutil.Process(); baseline=proc.memory_info().rss;peak=[baseline];stop=threading.Event()
    def sample():
        while not stop.wait(.01): peak[0]=max(peak[0],proc.memory_info().rss)
    worker=threading.Thread(target=sample);worker.start();start=time.perf_counter()
    result=ccc_test(d,'y',['x'],group='group',time='year',cohort='gvar',alltests=True)
    elapsed=time.perf_counter()-start;stop.set();worker.join()
    assert result.status=='ok'
    row=dict(n_cell=ncell,N=len(d),N_untreated=result.diagnostics['N'],U=24,K=1,P1=48,P2=35,seconds=elapsed,baseline_rss_bytes=baseline,peak_sampled_rss_bytes=peak[0])
    rows.append(row); print(row,flush=True)
report=dict(platform=platform.platform(),processor=platform.processor(),logical_cpus=os.cpu_count(),physical_memory_bytes=psutil.virtual_memory().total,method='RSS sampled each 10ms; baseline after fixture allocation; Python process only; single sequential run per size',runs=rows)
(root/'validation/expected/benchmark.json').write_text(json.dumps(report,indent=2))
