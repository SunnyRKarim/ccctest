from pathlib import Path
import sys, os
import numpy as np
import pandas as pd
import pytest
from ccctest import ccc_test, ccc_trends, holm_two, select_specification
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'validation/reference'))
from dense import reference

@pytest.fixture
def d(): return pd.read_csv(ROOT/'validation/fixtures/original.csv')

def fit(d,out='y_state',covariates=('x',),**kw):
    return ccc_test(d,out,covariates,group='group',time='year',cohort='gvar',**kw)

@pytest.mark.parametrize('vce',['HC1','OLS'])
@pytest.mark.parametrize('out',['y_homogeneous','y_state','y_time','y_twoway'])
def test_dense_source(d,out,vce):
    f=fit(d,out,vce=vce,alltests=True)
    r=np.load(ROOT/f'validation/expected/{out}_{vce}.npz')
    np.testing.assert_allclose(f.tests[['W','Q','p']],r['tests'],rtol=1e-8,atol=1e-12)
    for stage in [1,2]:
        a=f.fits[f'stage{stage}']; u=f.diagnostics['U']
        np.testing.assert_allclose(a.beta,r[f'b{stage}'][u:],rtol=1e-8,atol=1e-8)
        np.testing.assert_allclose(a.intercepts,r[f'b{stage}'][:u],rtol=1e-8,atol=1e-8)
        np.testing.assert_allclose(a.covariance,r[f'v{stage}'][u:,u:],rtol=1e-8,atol=1e-8)
    assert (f.diagnostics['N'],f.diagnostics['U'],f.diagnostics['P1'],f.diagnostics['P2'])==(1200,24,48,35)

@pytest.mark.parametrize('vce',['HC1','OLS'])
def test_unbalanced(vce):
    d=pd.read_csv(ROOT/'validation/fixtures/unbalanced.csv')
    f=fit(d,'y',['x','z'],vce=vce,alltests=True); r=reference(d,'y',['x','z'],vce)
    np.testing.assert_allclose(f.tests[['W','Q','p']],r['tests'],rtol=1e-8,atol=1e-12)
    for i in [1,2]:
        np.testing.assert_allclose(f.fits[f'stage{i}'].covariance,r[f'v{i}'][r['u']:,r['u']:],rtol=1e-8,atol=1e-8)

@pytest.mark.parametrize('p1,pr,pt,want,reason',[
    (.2,np.nan,np.nan,'homogeneous','stage1_nonrejection'),
    (.05,.025,.7,'region','holm_region_only'),
    (.01,.7,.025,'time','holm_time_only'),
    (.01,.025,.05,'twoway','holm_both'),
    (.01,.3,.4,'twoway','holm_neither'),
    (.01,.025,.025,'twoway','holm_both'),
    (.01,np.nan,.01,'undetermined','stage2_failure'),
    (np.nan,.01,.01,'undetermined','stage1_failure'),
    (-.1,.01,.01,'undetermined','stage1_failure')])
def test_decisions(p1,pr,pt,want,reason):
    assert select_specification(p1,pr,pt)==(want,reason)

def test_holm_gate(d):
    np.testing.assert_allclose(holm_two(.01,.04),[.02,.04])
    np.testing.assert_allclose(holm_two(.04,.01),[.04,.02])
    with pytest.raises(ValueError): holm_two(np.nan,.1)
    f=fit(d,'y_homogeneous'); assert not f.tests.loc['region','performed'];assert np.isnan(f.tests.loc['region','p'])
    f=fit(d,'y_homogeneous',alltests=True);assert f.tests.loc['region','performed']==1;assert f.tests.loc['region','used']==0

def test_invariance(d):
    base=fit(d,alltests=True)
    a=d.sample(frac=1,random_state=31).copy();a['group']=a.group.map({1:'Z',2:'B',3:'Q',4:'D',5:'X',6:'A'});a.x=2.3*a.x+7
    other=fit(a,alltests=True)
    np.testing.assert_allclose(base.tests[['W','p']],other.tests[['W','p']],rtol=1e-8,atol=1e-10)

def test_basis_and_reparameterization(d):
    d['category']=d.id%3;d['x2']=d.x**2
    f=fit(d,covariates=['x','category','x2'],categorical=['category'],alltests=True)
    assert f.status=='ok';assert f.diagnostics['K']==4
    a=pd.read_csv(ROOT/'validation/fixtures/unbalanced.csv'); b=a.copy();b['x']=2*a.x+.3*a.z;b['z']=a.x-2*a.z
    f=fit(a,'y',['x','z'],alltests=True); h=fit(b,'y',['z','x'],alltests=True)
    np.testing.assert_allclose(f.tests[['W','p']],h.tests[['W','p']],rtol=1e-8,atol=1e-10)

def test_failures(d):
    d['duplicate']=d.x
    assert fit(d,covariates=['x','duplicate']).status=='undetermined'
    d['constant']=d.group
    assert fit(d,covariates=['constant']).status=='undetermined'
    with pytest.raises(ValueError): fit(d,vce='cluster')
    with pytest.raises(TypeError): fit(d,weights=np.ones(len(d)))
    with pytest.raises(ValueError): ccc_test(d,'y_state',['x'],group='group',time='year')
    a=d.copy();a.loc[0,'gvar']=100
    with pytest.raises(ValueError): fit(a)
    a=d.copy();a.loc[0,'x']=np.inf
    with pytest.raises(ValueError): fit(a)
    with pytest.raises(ValueError): fit(d,subset=np.zeros(len(d),bool))
    with pytest.raises(ValueError): fit(d,alpha=1)

def test_missing(d):
    a=d.copy();a.loc[0,'x']=np.nan;a.loc[6,'gvar']=np.nan
    f=fit(a,alltests=True)
    assert f.diagnostics['N']==1198
    assert not f.sample[0] and not f.sample[6]
    a['u']=(a.d==0).astype(float);a.loc[1,'u']=0
    with pytest.raises(ValueError): ccc_test(a,'y_state',['x'],group='group',time='year',untreated='u')

def test_disconnected_and_diagnostic_failure():
    rng=np.random.default_rng(521)
    rows=[]
    for g,t in [(1,1),(1,2),(2,1),(2,2),(3,3),(3,4),(4,3),(4,4)]:
        for x,e in zip(rng.normal(size=100),rng.normal(size=100)):
            rows.append((g,t,0,x,e+50*g*x))
    d=pd.DataFrame(rows,columns=['group','year','gvar','x','y_state'])
    f=fit(d,alltests=True);assert f.reason=='stage2_failure';assert np.isfinite(f.tests.loc['omnibus','p'])
    # Preserve a valid stage-one nonrejection if the unused additive fit fails.
    from unittest.mock import patch
    import ccctest.core as core
    original=core._fit
    def only_stage1(*args,**kwargs):
        if args[4]=='A': raise core.NumericalFailure('diagnostic failure')
        return original(*args,**kwargs)
    original_data=pd.read_csv(ROOT/'validation/fixtures/original.csv')
    with patch.object(core,'_fit',side_effect=only_stage1):
        f=fit(original_data,'y_homogeneous',alltests=True)
    assert f.selected=='homogeneous';assert f.diagnostics['errors']['stage2']=='diagnostic failure'

def test_plot_algebra():
    d=pd.read_csv(ROOT/'validation/fixtures/plots.csv')
    ipt=ccc_trends(d,'ipt',['x','x2'],group='group',time='year',cohort='gvar')
    p=ipt.pairs
    np.testing.assert_allclose(p.delta_t,p.delta_c,atol=1e-9)
    # Conditional trend slopes differ even though integrated changes agree.
    assert np.any(abs((p.beta_st1-p.beta_sb1)-(p.beta_ct1-p.beta_cb1))>.5)
    np.testing.assert_allclose(ipt.series.query("panel=='integrated'").treated,2+.5*np.arange(2,9),atol=1e-9)
    for row in p.itertuples():
        target=d.loc[(d.group==row.focal)&(d.year==row.time)]
        assert abs(row.mu2-target.x2.mean())<1e-12
        assert abs(row.mu2-target.x.mean()**2)>1
        for end in ['st','sb','ct','cb']:
            predictions=getattr(row,f'theta_{end}')+getattr(row,f'beta_{end}1')*target.x+getattr(row,f'beta_{end}2')*target.x2
            assert abs(predictions.mean()-getattr(row,f'pred_{end}'))<1e-9
    cpt=ccc_trends(d,'cpt',['x','x2'],group='group',time='year',cohort='gvar')
    adj=cpt.series.query("panel=='homogeneous'")
    np.testing.assert_allclose(np.diff(adj.treated),2,atol=1e-9)
    np.testing.assert_allclose(np.diff(adj.control),2,atol=1e-9)
    raw=cpt.series.query("panel=='raw'")
    assert np.max(abs(np.diff(raw.treated)-np.diff(raw.control)))>1
    ordinary=ccc_trends(d,'ordinary',['fixed_x'],group='group',time='year',cohort='gvar')
    raw=ordinary.series.query("panel=='raw'")
    np.testing.assert_allclose(np.diff(raw.treated),np.diff(raw.control),atol=1e-9)

def test_plot_matches_dates_and_side_effects(d):
    old=d.copy(deep=True);rng=np.random.get_state();cwd=os.getcwd()
    tr=ccc_trends(d,'y_state',['x'],group='group',time='year',cohort='gvar',matches={g:{5:.3,6:.7} for g in [1,2,3,4]},focal_weights={1:.1,2:.2,3:.3,4:.4})
    p=tr.pairs; expected=np.sum(p.delta_c*p.control_weight*p.focal_weight)
    assert abs(tr.series.iloc[-1].control-expected)<1e-12
    pd.testing.assert_frame_equal(d,old);assert cwd==os.getcwd();assert np.array_equal(rng[1],np.random.get_state()[1])
    a=d.copy();a['year']=a.year*2;a['gvar']=a.gvar*2
    tr=ccc_trends(a,'y_state',['x'],group='group',time='year',cohort='gvar');assert tr.diagnostics['intervals']==[2]
    with pytest.raises(ValueError): ccc_trends(d.loc[~((d.group==5)&(d.year==1))],'y_state',['x'],group='group',time='year',cohort='gvar')
    with pytest.raises(ValueError): ccc_trends(d,'y_state',['x'],group='group',time='year',cohort='gvar',matches={1:{1:1}})

def test_no_f_reference(d):
    from scipy.stats import f as fdist
    a=fit(d,vce='OLS');w=a.tests.loc['omnibus','W'];q=a.tests.loc['omnibus','Q']
    assert abs(a.tests.loc['omnibus','p']-fdist.sf(w/q,q,1152))>1e-4

def test_every_adjustment_against_dense(d):
    from plots import dense_trends
    d['x2']=d.x**2
    for ref in [np.zeros(2),np.array([.2,1.3])]:
        cells,values=dense_trends(d,'y_state',['x','x2'],ref)
        tr=ccc_trends(d,'y_state',['x','x2'],group='group',time='year',cohort='gvar',reference=ref)
        for panel,m in zip(['homogeneous','region','time','twoway'],['H','R','T','TW']):
            for t in [1,2]:
                row=tr.series.loc[(tr.series.panel==panel)&(tr.series.time==t)].iloc[0]
                treated=np.mean([values[m][cells.index((g,t))] for g in [1,2,3,4]])
                control=np.mean([values[m][cells.index((g,t))] for g in [5,6]])
                np.testing.assert_allclose([row.treated,row.control],[treated,control],atol=1e-9)

def test_pure_interaction_neither():
    rows=[];x=np.tile(np.linspace(-2,2,15),4);A=np.column_stack([np.ones(len(x)),x]);v=x**3;e=v-A@np.linalg.lstsq(A,v,rcond=None)[0]
    for g in [1,2]:
        for t in [1,2]:
            y=10*g+t+20*(-1)**(g+t)*x+e
            rows.extend((g,t,0,xx,yy) for xx,yy in zip(x,y))
    d=pd.DataFrame(rows,columns=['group','year','gvar','x','y_state'])
    assert fit(d).reason=='holm_neither'

def test_insufficient_df_and_singular_covariance(d):
    a=d.groupby(['group','year']).head(1)
    assert fit(a).status=='undetermined'
    from ccctest.core import _fit,_wald,_equal,NumericalFailure
    # Constant zero outcome gives exactly zero score covariance.
    u=d.loc[d.d==0]
    f=_fit(np.zeros(len(u)),u[['x']].to_numpy(),u.group.to_numpy(),u.year.to_numpy(),'TW')
    with pytest.raises(NumericalFailure): _wald(f,_equal(24,1,24))
