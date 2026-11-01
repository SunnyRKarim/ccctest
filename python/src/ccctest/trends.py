"""Auditable trend data and optional plotting, independent of CCC selection."""
from dataclasses import dataclass
from typing import Any, Sequence
import numpy as np
import pandas as pd
from .core import _prepare, _fit

PANEL_NAMES = ['raw','homogeneous','region','time','twoway','integrated']

@dataclass
class TrendResult:
    series: pd.DataFrame
    pairs: pd.DataFrame
    cells: pd.DataFrame
    coefficients: pd.DataFrame
    matches: pd.DataFrame
    reference: np.ndarray
    diagnostics: dict[str, Any]

    def plot(self, panels='core'):
        """Return a reusable matplotlib Figure; no plotting dependency at import."""
        import matplotlib.pyplot as plt
        names = PANEL_NAMES if panels=='all' else ['raw','homogeneous','integrated'] if panels=='core' else [panels]
        if not set(names).issubset(PANEL_NAMES): raise ValueError('Unknown panel')
        fig, axes=plt.subplots((len(names)+2)//3,min(len(names),3),figsize=(12,3.7*((len(names)+2)//3)),squeeze=False)
        for ax,name in zip(axes.flat,names):
            d=self.series.loc[self.series.panel==name]
            for col,color,marker in [('treated','#2367a3','o'),('control','#b64452','^')]:
                ax.plot(d.time,d[col],label=col.title(),color=color,marker=marker,linestyle='-' if col=='treated' else '--')
            ax.set(title=name.title(),xlabel='Period',ylabel='Outcome change' if name=='integrated' else 'Outcome level')
            ax.legend(frameon=False); ax.grid(alpha=.15)
        for ax in list(axes.flat)[len(names):]: ax.set_visible(False)
        fig.suptitle('Untreated trend diagnostics')
        fig.text(.02,.01,'Fixed comparison weights; adjacent observed intervals. Diagnostics do not establish parallel trends.',fontsize=9)
        fig.tight_layout(rect=[0,.035,1,.96])
        return fig

def ccc_trends(data: pd.DataFrame, outcome: str, covariates: Sequence[str], *,
               group: str, time: str, cohort: str, categorical: Sequence[str]=(),
               subset=None, focal=None, window=None, controls='never', matches=None,
               focal_weights=None, reference='zero') -> TrendResult:
    """Construct six numeric panels using one common untreated plotting sample."""
    d,z,sample,basis,diag=_prepare(data,outcome,covariates,group,time,cohort,None,subset,categorical)
    gs=d.groupby(group)[cohort].first().to_dict()
    focal=sorted([g for g,v in gs.items() if v!=0]) if focal is None else list(focal)
    if not focal or len(set(focal))!=len(focal) or any(g not in gs or gs[g]==0 for g in focal):
        raise ValueError('Supply distinct observed future-adopting focal regions')
    first=min(gs[g] for g in focal)
    mask=d[time].to_numpy()<first
    if window is not None:
        if len(window)!=2 or window[0]>window[1] or window[1]>=first:
            raise ValueError('Window must be ordered and wholly pretreatment')
        mask &= d[time].between(*window).to_numpy()
    dates=sorted(d.loc[mask,time].unique())
    if len(dates)<2: raise ValueError('At least two common pretreatment dates are required')
    if controls not in ('never','notyet'): raise ValueError('controls must be never or notyet')
    eligible=[g for g,v in gs.items() if g not in focal and (v==0 or (controls=='notyet' and v>dates[-1]))]
    if not eligible: raise ValueError('No fixed eligible controls throughout plot window')
    if matches is None: matches={g:{c:1/len(eligible) for c in eligible} for g in focal}
    if set(matches)!=set(focal): raise ValueError('Matches must specify every focal region exactly once')
    if focal_weights is None: focal_weights={g:1/len(focal) for g in focal}
    if set(focal_weights)!=set(focal): raise ValueError('Focal weights must cover exactly the focal set')
    def valid_weights(values):
        a=np.array(list(values),dtype=float)
        return len(a)>0 and np.isfinite(a).all() and (a>=0).all() and abs(a.sum()-1)<=1e-10
    if not valid_weights(focal_weights.values()): raise ValueError('Focal weights must be nonnegative and sum to one')
    matchrows=[]
    for g,cs in matches.items():
        if not set(cs).issubset(eligible) or g in cs or not valid_weights(cs.values()):
            raise ValueError('Invalid/self/ineligible matches or unnormalized control weights')
        for c,w in cs.items(): matchrows.append((g,c,focal_weights[g],w))
    used=set(focal)|{c for cs in matches.values() for c in cs}
    mask &= d[group].isin(used).to_numpy()
    d=d.loc[mask]; z=z[mask]
    y=d[outcome].to_numpy(); groups=d[group].to_numpy(); times=d[time].to_numpy()
    cells=sorted(set(zip(groups,times)))
    if len(cells)!=len(used)*len(dates): raise ValueError('Missing endpoint cell in fixed comparison set')
    k=z.shape[1]
    if isinstance(reference,str):
        if reference not in ('zero','pooled'): raise ValueError('reference must be zero, pooled or K-vector')
        zref=np.zeros(k) if reference=='zero' else z.mean(axis=0)
    else: zref=np.asarray(reference,dtype=float)
    if zref.shape!=(k,) or not np.isfinite(zref).all(): raise ValueError('Reference must be a finite K-vector')
    fits={m:_fit(y,z,groups,times,m,'OLS') for m in ['H','R','T','TW']}
    f=fits['TW']; index={c:i for i,c in enumerate(cells)}
    cellrows=[]; limits={}; zs={}
    for j,(g,t) in enumerate(cells):
        a=z[(groups==g)&(times==t)]; zs[g,t]=a; limits[g,t]=(a.min(axis=0),a.max(axis=0))
        cellrows.append(dict(group=g,time=t,n=f.counts[j],mean_y=f.means[j,0],**{f'mu{h+1}':v for h,v in enumerate(f.means[j,1:])}))
    series=[]; coef=[]
    for name,model in zip(PANEL_NAMES[:5],[None,'H','R','T','TW']):
        vals=f.means[:,0] if model is None else fits[model].intercepts+fits[model].slopes@zref
        if model:
            for j,(g,t) in enumerate(cells):
                coef.append(dict(model=name,group=g,time=t,theta=fits[model].intercepts[j],**{f'beta{h+1}':v for h,v in enumerate(fits[model].slopes[j])}))
        for t in dates:
            treated=sum(focal_weights[g]*vals[index[g,t]] for g in focal)
            control=sum(a*w*vals[index[c,t]] for g,c,a,w in matchrows)
            series.append(dict(panel=name,time=t,baseline=np.nan,treated=treated,control=control,gap=treated-control))
    pairs=[]
    for b,t in zip(dates[:-1],dates[1:]):
        dt=dc=0.
        for g,c,a,w in matchrows:
            mu=f.means[index[g,t],1:]
            endpoints=[(g,t),(g,b),(c,t),(c,b)]
            pred=[float(f.intercepts[index[e]]+f.slopes[index[e]]@mu) for e in endpoints]
            row=dict(focal=g,control=c,time=t,baseline=b,focal_weight=a,control_weight=w,
                     pred_st=pred[0],pred_sb=pred[1],pred_ct=pred[2],pred_cb=pred[3],delta_t=pred[0]-pred[1],delta_c=pred[2]-pred[3])
            row.update({f'mu{h+1}':v for h,v in enumerate(mu)})
            for label,e in zip(['st','sb','ct','cb'],endpoints):
                j=index[e]; row[f'theta_{label}']=f.intercepts[j]
                row.update({f'beta_{label}{h+1}':v for h,v in enumerate(f.slopes[j])})
                row[f'outside_{label}']=bool(np.any(limits[g,t][0]<limits[e][0]) or np.any(limits[g,t][1]>limits[e][1]))
            pairs.append(row);dt+=a*w*row['delta_t'];dc+=a*w*row['delta_c']
        series.append(dict(panel='integrated',time=t,baseline=b,treated=dt,control=dc,gap=dt-dc))
    diag.update(N_test_eligible=diag['N'],N_plot=len(d),basis=basis,window=[dates[0],dates[-1]],intervals=np.diff(dates).tolist(),
                reference='explicit' if not isinstance(reference,str) else reference,range_warning='Marginal ranges do not establish joint overlap')
    return TrendResult(pd.DataFrame(series),pd.DataFrame(pairs),pd.DataFrame(cellrows),pd.DataFrame(coef),
                       pd.DataFrame(matchrows,columns=['focal','control','focal_weight','control_weight']),zref,diag)
