import json, datetime as dt, math
from facts import *
J=json.load(open('days.json')); M={dt.date.fromisoformat(k):v for k,v in J['days'].items()}
TR=['dw','mt','ex','em','rd']; NAME=dict(dw='Deep Work',mt='Meetings',ex='Exercise',em='Email',rd='Reading')
GOAL={'dw':1500,'mt':480,'ex':45,'em':30,'rd':9000}
EXTRA=1/60
def g(d,t): return M.get(d,{}).get(t,0)+(EXTRA if (t=='dw' and d==TODAY) else 0)
def week(k): return [W0+dt.timedelta(7*k+i) for i in range(7)]
def wt(k,t=None): return sum((g(d,t) if t else sum(g(d,x) for x in TR)) for d in week(k))
hm=lambda m: f"{int(m+1e-9)//60}:{int(m+1e-9)%60:02d}"
def sd(m): return ('−' if m<0 else '+')+hm(abs(m))
def pct(v,b): return f"{round((v-b)/b*100):+d}%".replace('+-','-')
cur={t:wt(11,t) for t in TR}; last={t:wt(10,t) for t in TR}
C=sum(cur.values()); L=sum(last.values())
print("HERO", hm(C), ('↓' if C<L else '↑'), hm(abs(C-L)), pct(C,L).replace('-','−') if C<L else pct(C,L), "vs last week")
for t in TR: print(f"  {NAME[t]:10s} {hm(cur[t]):>6} {hm(last[t]):>6} {sd(cur[t]-last[t]):>7}")
print(f"  TOTAL      {hm(C):>6} {hm(L):>6} {sd(C-L):>7}")
# split bars: width 400, gaps 2
def split(parts,scale):
    vis=[p for p in parts if p>0]; gaps=2*(len(vis)-1); raw=[p/scale*400 for p in vis]; s=sum(raw)
    k=(400-gaps)/s if s+gaps>400 else 1
    return [round(r*k,2) for r in raw]
S=max(C,L)
print("SPLIT this",split([cur[t] for t in TR],S),"last",split([last[t] for t in TR],S))
weeks=[wt(k) for k in range(4,12)]
print("TREND", [round(w/max(weeks)*96) for w in weeks], [hm(w) for w in weeks], "avg", hm(sum(weeks)/8))
dws=[wt(k,'dw') for k in range(4,12)]
scale=max(1500,max(dws))
print("04 bars", [round(w/scale*100) for w in dws], [hm(w) for w in dws], "goal line top", round(100-1500/scale*100,2),
      "vs avg", pct(dws[-1],sum(dws)/8))
print("04 hero", hm(cur['dw']), ('↓' if cur['dw']<last['dw'] else '↑'), hm(abs(cur['dw']-last['dw'])), pct(cur['dw'],last['dw']), "vs last week")
RDW=9000/365*7
def whit(t,k):
    goal={'dw':1500,'mt':480,'rd':RDW}[t]; return wt(k,t)>=goal
for t in ['dw','mt','rd']:
    s=''.join('1' if whit(t,k) else '0' for k in range(11))
    print(t,'weeks',s, 'hits',s.count('1'),'/11', f"{round(s.count('1')/11*100)}%")
days=[W0+dt.timedelta(i) for i in range(82)]
for t in ['ex','em']:
    s=''.join('1' if g(d,t)>=GOAL[t] else '0' for d in days[:81])
    print(t,'days',s,'dots Oct12-22',s[70:81])
# line: by same point (Fri 20:56) using post
post=J['post']
for t,G in [('dw',1500),('mt',480),('ex',315)]:
    vals=[]
    for k in range(4,11):
        s=sum(g(d,t) for d in week(k)[:5])-(post.get(str(k),{}).get(t,0) if t in('dw','mt') else 0)
        vals.append(s/G)
    vals.append(sum(g(d,t) for d in week(11)[:5])/G)
    ys=[round(130-(v-0.5)*200,1) for v in vals]
    print('line',t,[round(v,3) for v in vals],'y',ys)
# heat
T=1500/7+480/7+45+30+9000/365
lv={}
for j in range(83):
    d=D0+dt.timedelta(j); s=min(1,sum(g(d,x) for x in TR)/T)
    lv[d]=0 if s<0.125 else 1 if s<0.25 else 2 if s<0.99999 else 3
print('perfect',sum(1 for v in lv.values() if v==3),'diffs vs design',[(d.strftime('%b %d'),HEAT[d],l) for d,l in lv.items() if l!=HEAT[d]])
ytd=sum(v['rd'] for k,v in J['days'].items() if k.startswith('2026'))
print('reading Aug-Oct',ytd,'rest for Jan-Jul',5770-ytd)
