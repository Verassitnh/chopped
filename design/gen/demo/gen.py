"""Solve the per-day demo table against the (consistency-edited) designs. Writes days.json.
Decisions (design edits) are encoded as hard constraints below."""
import pulp, json, datetime as dt
from facts import *
T=1500/7+480/7+45+30+9000/365
RDW=9000/365*7
TR=['dw','mt','ex','em','rd']
days=[D0+dt.timedelta(i) for i in range((TODAY-D0).days+1)]
# ---- design after edits
HEAT2=dict(HEAT)
for d,l in [((8,31),2),((9,2),2),((9,8),2),((9,9),2),((9,11),2),((9,18),1),((10,22),3)]:
    HEAT2[dt.date(2026,*d)]=l
EX2=EX[:]; EX2[25]=0          # Fri Aug 28 (empty heat cell)
EM2=EM[:]
DW2=DW[:]; DW2[1]=0; DW2[3]=0
MT2=MT[:]; MT2[1]=0
RD2=RD[:]; RD2[11]=0          # current week not hit (3w)
P=pulp.LpProblem('c',pulp.LpMinimize)
m={(d,t):pulp.LpVariable(f"m_{d:%m%d}_{t}",0,None,cat='Integer') for d in days for t in TR}
FRI={k:W0+dt.timedelta(7*k+4) for k in range(4,11)}
post={(k,t):pulp.LpVariable(f"p_{k}_{t}",0,None,cat='Integer') for k in FRI for t in ['dw','mt']}
for k in FRI:
    P+= post[k,'dw']+post[k,'mt']<=180
    for t in ['dw','mt']: P+= post[k,t]<=m[FRI[k],t]
CAP={'dw':540,'mt':300,'ex':120,'em':90,'rd':200}
reg=[]
for d in days:
    for t in TR: P+= m[d,t]<=CAP[t]
    P+= pulp.lpSum(m[d,t] for t in TR)<=720
    if d.weekday()>=5: reg.append(1.0*(m[d,'dw']+m[d,'mt']))
reg+= [2.0*v for v in post.values()]
# this week
tw=[W0+dt.timedelta(77+i) for i in range(5)]
for d,v in zip(tw,[252,306,228,360,223]): P+= m[d,'dw']==v
P+= m[tw[4],'ex']==30; P+= m[tw[4],'em']==27
P+= pulp.lpSum(m[d,'ex'] for d in tw)==225
P+= pulp.lpSum(m[d,'em'] for d in tw)==179
P+= pulp.lpSum(m[d,'mt'] for d in tw)==324
P+= pulp.lpSum(m[d,'rd'] for d in tw)==90
# heat (hard, with 1-minute margins)
UB={0:T/8,1:T/4,2:T,3:10**4}; LB={0:0,1:T/8,2:T/4,3:T}
for d in days:
    tot=pulp.lpSum(m[d,t] for t in TR); l=HEAT2[d]
    if l>0: P+= tot>=LB[l]+1
    P+= tot<=UB[l]-1
# daily lanes (idx 0..80 completed; today fixed)
for name,lanev,goal in [('ex',EX2,45),('em',EM2,30)]:
    for i in range(81):
        d=W0+dt.timedelta(i)
        if lanev[i]: P+= m[d,name]>=goal
        else: P+= m[d,name]<=goal-1
# weekly hits
WG={'dw':1500,'mt':480,'rd':RDW}
for t,pat in [('dw',DW2),('mt',MT2),('rd',RD2)]:
    for k in range(11):
        s=pulp.lpSum(m[W0+dt.timedelta(7*k+i),t] for i in range(7))
        if pat[k]: P+= s>=WG[t]*1.02
        else: P+= s<=WG[t]-1
DWT={4:1560,5:1290,6:1530,7:1650,8:1590,9:1710,10:1545}
for k,v in DWT.items(): P+= pulp.lpSum(m[W0+dt.timedelta(7*k+i),'dw'] for i in range(7))==v
# goal % lines: share of the weekly goal logged by the same point in the week (Fri 20:56)
LG={'dw':1500,'mt':480,'ex':315}
for t in ['dw','mt','ex']:
    for j,k in enumerate(range(4,11)):
        s=pulp.lpSum(m[W0+dt.timedelta(7*k+i),t] for i in range(5)) - (post[k,t] if t in('dw','mt') else 0)
        tgt=LINE[t][j]*LG[t]
        P+= s>=round(tgt-0.0024*LG[t]+0.4999); P+= s<=int(tgt+0.0024*LG[t])
# perfect days = 16
P+= pulp.lpSum(1 for d in days if HEAT2[d]==3)==16
# realism: prefer weekday work, spread DW evenly-ish (penalise big days)
big={d:pulp.LpVariable(f"big_{d:%m%d}",0) for d in days}
for d in days: P+= big[d]>=m[d,'dw']-330
reg+= [0.5*v for v in big.values()]
for t,lim in [('mt',150),('rd',120),('ex',60),('em',45)]:
    for d in days:
        o=pulp.LpVariable(f"o_{t}_{d:%m%d}",0); P+= o>=m[d,t]-lim; reg.append(2*o)
# misses shouldn't be near-zero crumbs: discourage 1..9 minute entries softly by rewarding 0 (skip; keep simple)
P+= pulp.lpSum(reg)
P.solve(pulp.HiGHS(msg=False,timeLimit=120))
print(pulp.LpStatus[P.status], pulp.value(P.objective))
res={d.isoformat():{t:int(round(m[d,t].value())) for t in TR} for d in days}
json.dump({'days':res,'post':{str(k):{t:int(round(post[k,t].value())) for t in ['dw','mt']} for k in FRI}},open('days.json','w'),indent=0)
