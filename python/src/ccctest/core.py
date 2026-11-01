"""Cell-intercept-absorbing native numerical implementation."""
from dataclasses import dataclass, field
from typing import Any, Sequence
import numpy as np
import pandas as pd
from scipy.linalg import cho_factor, cho_solve
from scipy.stats import chi2

MAX_SLOPES = 2000

class NumericalFailure(ValueError):
    """The requested, unreduced hypothesis cannot be estimated reliably."""

@dataclass
class AuxiliaryFit:
    beta: np.ndarray
    covariance: np.ndarray
    intercepts: np.ndarray
    slopes: np.ndarray
    means: np.ndarray
    cells: list[tuple[Any, Any]]
    counts: np.ndarray
    n: int
    parameters: int
    rank: int
    condition: float

@dataclass
class CCCResult:
    tests: pd.DataFrame
    selected: str
    reason: str
    status: str
    sample: np.ndarray
    basis: list[str]
    diagnostics: dict[str, Any]
    fits: dict[str, AuxiliaryFit] = field(default_factory=dict)
    restrictions: dict[str, np.ndarray] = field(default_factory=dict)

    def __str__(self) -> str:
        return f'CCC selected specification: {self.selected} ({self.reason})\n{self.tests.to_string()}'

def holm_two(p_region: float, p_time: float) -> np.ndarray:
    p = np.array([p_region, p_time], dtype=float)
    if not np.isfinite(p).all() or np.any((p < 0) | (p > 1)):
        raise ValueError('Two finite p-values in [0,1] are required')
    order = np.argsort(p, kind='stable')
    out = np.empty(2)
    out[order] = np.minimum(1, np.maximum.accumulate(p[order] * [2, 1]))
    return out

def select_specification(p1: float, pr: float = np.nan, pt: float = np.nan,
                         alpha: float = .05) -> tuple[str, str]:
    if not 0 < alpha < 1:
        raise ValueError('alpha must be in (0,1)')
    if not np.isfinite(p1) or not 0 <= p1 <= 1:
        return 'undetermined', 'stage1_failure'
    if p1 > alpha:
        return 'homogeneous', 'stage1_nonrejection'
    try:
        r, t = holm_two(pr, pt) <= alpha
    except ValueError:
        return 'undetermined', 'stage2_failure'
    if r and not t:
        return 'region', 'holm_region_only'
    if t and not r:
        return 'time', 'holm_time_only'
    return 'twoway', 'holm_both' if r else 'holm_neither'

def _prepare(data, outcome, covariates, group, time, cohort=None, untreated=None,
             subset=None, categorical=()):
    if not cohort and not untreated:
        raise ValueError('Specify cohort (0=never) or untreated; full data are not assumed untreated')
    if not covariates or len(set(covariates)) != len(covariates):
        raise ValueError('Supply distinct covariate columns')
    if not set(categorical).issubset(covariates):
        raise ValueError('Categorical columns must be included in covariates')
    d = data.copy().reset_index(drop=True)
    mask = np.ones(len(d), dtype=bool) if subset is None else np.asarray(subset)
    if mask.shape != (len(d),) or mask.dtype.kind != 'b':
        raise ValueError('subset must be a positional Boolean mask')
    for name in [outcome, time, *[x for x in covariates if x not in categorical], *([cohort] if cohort else []), *([untreated] if untreated else [])]:
        if not pd.api.types.is_numeric_dtype(d[name]):
            raise ValueError(f'{name} must be numeric; encode dates in a declared numeric unit')
        if np.isinf(d[name].to_numpy(dtype=float)).any():
            raise ValueError(f'{name} contains infinity')
    if cohort:
        if (d.loc[mask, time] == 0).any():
            raise ValueError('time=0 conflicts with never-treated cohort code')
        if (d.groupby(group)[cohort].nunique() > 1).any():
            raise ValueError('Cohort must be constant within policy region')
        eligible = d[cohort].notna() & ((d[cohort] == 0) | (d[time] < d[cohort]))
    if untreated:
        if not d[untreated].dropna().isin([0, 1]).all():
            raise ValueError('untreated must contain 0, 1 or missing')
        if (d.groupby([group, time])[untreated].nunique() > 1).any():
            raise ValueError('Treatment status must be constant within cells')
        for _, a in d.dropna(subset=[group,time,untreated]).groupby(group):
            if (np.diff(a.sort_values(time)[untreated].to_numpy()) > 0).any():
                raise ValueError('Treatment reversals are unsupported')
        if cohort:
            known = d[cohort].notna() & d[untreated].notna() & d[time].notna()
            if (eligible[known].to_numpy() != d.loc[known, untreated].to_numpy()).any():
                raise ValueError('Cohort and untreated indicator disagree')
            eligible &= d[untreated].notna()
        else:
            eligible = d[untreated] == 1
    complete = d[[outcome, group, time, *covariates]].notna().all(axis=1).to_numpy()
    sample = mask & eligible.to_numpy() & complete
    if not sample.any():
        raise ValueError('No complete untreated observations')
    work = d.loc[sample].copy()
    basis = []
    columns = []
    for col in covariates:
        if col in categorical:
            levels = sorted(work[col].unique())
            if len(levels)<2:
                raise ValueError(f'{col} has no nonreference category')
            for level in levels[1:]:
                basis.append(f'{col}[{level}]')
                columns.append((work[col] == level).to_numpy(dtype=float))
        else:
            basis.append(col); columns.append(work[col].to_numpy(dtype=float))
    z = np.column_stack(columns)
    diag = dict(N_input=len(d), N_restricted=int(mask.sum()),
                excluded_eligibility=int((mask & ~eligible.to_numpy()).sum()),
                excluded_complete_case=int((mask & eligible.to_numpy() & ~complete).sum()), N=len(work))
    return work, z, sample, basis, diag

def _mapping(j, s, t, u, ng, nt, k, model):
    l = {'H': k, 'R':ng*k, 'T':nt*k, 'TW':u*k, 'A':(ng+nt-1)*k}[model]
    m = np.zeros((k,l))
    block = {'H':0,'R':s,'T':t,'TW':j,'A':s}[model]
    m[:,block*k:(block+1)*k]=np.eye(k)
    if model == 'A' and t:
        m[:,(ng+t-1)*k:(ng+t)*k]=np.eye(k)
    return m

def _factor(a, label):
    rank = np.linalg.matrix_rank(a)
    condition = np.linalg.cond(a)
    if rank < len(a) or condition > 1e12 or not np.isfinite(condition):
        raise NumericalFailure(f'{label}: rank {rank}/{len(a)}, condition {condition:.4g}')
    try:
        return cho_factor(a, lower=True), rank, condition
    except np.linalg.LinAlgError as exc:
        raise NumericalFailure(f'{label}: not positive definite') from exc

def _fit(y, z, groups, times, model, vce='HC1'):
    cells=sorted(set(zip(groups,times)))
    gs,ts=sorted(set(groups)),sorted(set(times))
    n,k=z.shape; u=len(cells)
    l={'H':k,'R':len(gs)*k,'T':len(ts)*k,'TW':u*k,'A':(len(gs)+len(ts)-1)*k}[model]
    if l>MAX_SLOPES:
        raise NumericalFailure(f'resource_limit: {l} slopes exceeds {MAX_SLOPES}')
    p=u+l
    if n<=p:
        raise NumericalFailure(f'insufficient residual df: N={n}, P={p}')
    xx=np.zeros((l,l)); xy=np.zeros(l); chunks=[]; means=[]; counts=[]
    for j,(s,t) in enumerate(cells):
        ix=(groups==s)&(times==t)
        yz=np.column_stack([y[ix],z[ix]])
        mean=yz.mean(axis=0); centered=yz-mean
        m=_mapping(j,gs.index(s),ts.index(t),u,len(gs),len(ts),k,model)
        x,cy=centered[:,1:],centered[:,0]
        xx+=m.T@(x.T@x)@m; xy+=m.T@(x.T@cy)
        chunks.append((x,cy,m)); means.append(mean); counts.append(ix.sum())
    factor,rank,condition=_factor(xx,'centered slope design')
    beta=cho_solve(factor,xy); bread=cho_solve(factor,np.eye(l))
    meat=np.zeros((l,l)); sse=0.; slopes=[]
    for x,cy,m in chunks:
        slope=m@beta; residual=cy-x@slope; sse+=residual@residual
        score=x*residual[:,None]; meat+=m.T@(score.T@score)@m
        slopes.append(slope)
    covariance=bread*sse/(n-p) if vce=='OLS' else n/(n-p)*bread@meat@bread
    means=np.array(means); slopes=np.array(slopes)
    return AuxiliaryFit(beta,covariance,means[:,0]-np.sum(means[:,1:]*slopes,axis=1),slopes,means,cells,np.array(counts),n,p,rank,condition)

def _equal(count,k,l):
    r=np.zeros(((count-1)*k,l))
    for j in range(1,count):
        r[(j-1)*k:j*k,j*k:(j+1)*k]=np.eye(k)
        r[(j-1)*k:j*k,:k]=-np.eye(k)
    return r

def _wald(f,r):
    d=r@f.beta; c=r@f.covariance@r.T
    factor,rank,condition=_factor(c,'restriction covariance')
    w=float(d@cho_solve(factor,d))
    if not np.isfinite(w) or w<0:
        raise NumericalFailure('Nonfinite/negative Wald statistic')
    return w, len(r), float(chi2.sf(w,len(r)))

def ccc_test(data: pd.DataFrame, outcome: str, covariates: Sequence[str], *,
             group: str, time: str, cohort: str | None = None,
             untreated: str | None = None, vce: str = 'HC1', alpha: float = .05,
             alltests: bool = False, subset=None, categorical: Sequence[str] = ()) -> CCCResult:
    """Test equal untreated covariate coefficients; does not estimate an ATT."""
    vce=vce.upper()
    if vce=='HOMOSKEDASTIC': vce='OLS'
    if vce not in ('HC1','OLS'):
        raise ValueError('Only unweighted HC1/OLS; cluster/survey CCC inference is unsupported')
    if not 0<alpha<1: raise ValueError('alpha must be in (0,1)')
    d,z,sample,basis,diag=_prepare(data,outcome,covariates,group,time,cohort,untreated,subset,categorical)
    groups,times=d[group].to_numpy(),d[time].to_numpy()
    u=len(set(zip(groups,times))); s=len(set(groups)); t=len(set(times)); k=z.shape[1]
    if min(s,t)<2: raise ValueError('At least two untreated regions and periods are required')
    tests=pd.DataFrame(np.nan,index=['omnibus','region','time'],columns=['W','Q','p','p_holm','reject','performed','used'])
    tests['Q']=[k*(u-1),k*(s-1),k*(t-1)]; tests[['performed','used']]=0.
    fits={}; restrictions={}; diag.update(U=u,S=s,T=t,K=k,P1=u*(k+1),P2=u+k*(s+t-1),vce=vce,alpha=alpha,errors={},restriction_ranks={})
    for stage in ['stage1','stage2']:
        p1=tests.loc['omnibus','p']
        if stage=='stage2' and (not np.isfinite(p1) or (p1>alpha and not alltests)): break
        names=['omnibus'] if stage=='stage1' else ['region','time']
        tests.loc[names,'performed']=1.; tests.loc[names,'used']=float(stage=='stage1' or p1<=alpha)
        try:
            f=_fit(d[outcome].to_numpy(),z,groups,times,'TW' if stage=='stage1' else 'A',vce)
            fits[stage]=f
            if stage=='stage1': restrictions['omnibus']=_equal(u,k,len(f.beta))
            else:
                restrictions['region']=_equal(s,k,len(f.beta))
                restrictions['time']=np.column_stack([np.zeros((k*(t-1),s*k)),np.eye(k*(t-1))])
            for name in names:
                r=restrictions[name]
                diag['restriction_ranks'][name]=int(np.linalg.matrix_rank(r@f.covariance@r.T))
                try: tests.loc[name,['W','Q','p']]=_wald(f,restrictions[name])
                except NumericalFailure as exc: diag['errors'][name]=str(exc)
        except NumericalFailure as exc:
            diag['errors'][stage]=str(exc)
    p1,pr,pt=tests['p']
    if np.isfinite(p1): tests.loc['omnibus','reject']=float(p1<=alpha)
    if np.isfinite([pr,pt]).all():
        adjusted=holm_two(pr,pt)
        tests.loc[['region','time'],'p_holm']=adjusted
        tests.loc[['region','time'],'reject']=(adjusted<=alpha).astype(float)
    selected,reason=select_specification(p1,pr,pt,alpha)
    return CCCResult(tests,selected,reason,'undetermined' if selected=='undetermined' else 'ok',sample,basis,diag,fits,restrictions)
