import json, datetime as dt
from heat import L as HEAT
from gen import WANT_LEVEL
TR=['dw','mt','ex','em','rd']
GOAL={'dw':1500,'mt':480,'ex':45,'em':30,'rd':9000}
SHARE={'dw':1500/7,'mt':480/7,'ex':45,'em':30,'rd':9000/365}
T=sum(SHARE.values())
raw=json.load(open('days.json'))
M={dt.date.fromisoformat(k):v for k,v in raw.items()}
RUN_EXTRA=1/60   # running session's extra second
TODAY=dt.date(2026,10,23); W0=dt.date(2026,8,3)
def g(d,t): return M.get(d,{}).get(t,0)+(RUN_EXTRA if (t=='dw' and d==TODAY) else 0)
def week(k): return [W0+dt.timedelta(7*k+i) for i in range(7)]
def wt(k,t=None): return sum((g(d,t) if t else sum(g(d,x) for x in TR)) for d in week(k))
hm=lambda m: f"{int(m)//60}:{int(m)%60:02d}"
cur=wt(11)
print("this week", hm(cur), {t:hm(wt(11,t)) for t in TR})
print("last week", hm(wt(10)), {t:hm(wt(10,t)) for t in TR})
weeks=[wt(k) for k in range(4,12)]
print("trend", [round(w/max(weeks)*96) for w in weeks], "want [64,73,69,78,74,81,85,96]", "avg", hm(sum(weeks)/8), "want 29:42")
dws=[wt(k,'dw') for k in range(4,12)]
print("04 bars", [min(101,round(w/1500*100)) for w in dws], "want [67,73,68,82,76,85,78,91]",
      "vs avg(8)", f"{round((dws[-1]-sum(dws)/8)/(sum(dws)/8)*100):+d}%")
# goal hits weekly
def wfrac(k,t):
    goal = GOAL[t] if t in('dw','mt') else (GOAL[t]*7 if t in('ex','em') else 9000/365*7)
    return wt(k,t)/goal
for t,design in [('dw','01011011111'),('mt','11011101111'),('rd','011011101111')]:
    hits=''.join('1' if wfrac(k,t)>=1 else '0' for k in range(12))
    print(t,"weekly hits",hits[:11],hits[11],"design",design)
# daily series from Aug 3 to today
days=[W0+dt.timedelta(i) for i in range((TODAY-W0).days+1)]
def runs(s):
    out=[];st=None
    for i,v in enumerate(s+'0'):
        if v=='1' and st is None: st=i
        if v=='0' and st is not None: out.append((st,i-st)); st=None
    return out
for t,dots in [('ex','00010011111'),('em','01110011111')]:
    s=''.join('1' if g(d,t)>=GOAL[t] else '0' for d in days)
    r=runs(s[:-1] if s[-1]=='0' else s)
    cur_=0
    for v in reversed(s[:-1] if s[-1]=='0' else s):
        if v=='1': cur_+=1
        else: break
    print(t,"dots",s[-12:-1],"design",dots,"cur",cur_,"best",max(l for _,l in r))
    print("   lane",s)
# heat
D0=dt.date(2026,8,2)
lv=[]
for j in range(83):
    d=D0+dt.timedelta(j); s=min(1,sum(g(d,x) for x in TR)/T)
    l=0 if s<0.125 else 1 if s<0.25 else 2 if s<0.999 else 3
    lv.append(l)
diff=[( (D0+dt.timedelta(j)).strftime('%a %b %d'),HEAT[j],l) for j,l in enumerate(lv) if l!=HEAT[j]]
print("perfect",lv.count(3),"heat diffs",diff)
# line chart (prev weeks weekFraction; current = progress)
for t in ['dw','ex','mt']:
    vals=[round(wfrac(k,t)*100) for k in range(4,11)]
    curp = wt(11,t)/GOAL[t] if t!='ex' else g(TODAY,'ex')/45
    print("line",t,vals,round(curp*100))
print("line design dw [72,80,76,88,70,84,64,91] ex [57,71,86,100,86,71,86,67] mt [70,62,80,75,60,72,50,68]")
ytd=sum(g(d,'rd') for d in M if d.year==2026)
print("reading ytd",hm(ytd))
# sanity: no day > 16h
for d in M:
    if sum(M[d].values())>16*60: print("BIG DAY",d,M[d])
