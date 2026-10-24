import datetime as dt, json, sys
from design import ex as EX0, em as EM0
from heat import L as HEAT
TR=['dw','mt','ex','em','rd']
GOAL={'dw':1500,'mt':480,'ex':45,'em':30,'rd':9000}
SHARE={'dw':1500/7,'mt':480/7,'ex':45,'em':30,'rd':9000/365}
T=sum(SHARE.values())
E0,E1=0.125,0.25
D0=dt.date(2026,8,2)          # first heat cell (Sun)
W0=dt.date(2026,8,3)          # week idx 0 (Mon)
TODAY=dt.date(2026,10,23)
def day(i): return W0+dt.timedelta(i)
mins={}                        # date -> {tr: minutes}
def setm(d,tr,m):
    mins.setdefault(d,{t:0 for t in TR})[tr]=m
def getm(d,tr): return mins.get(d,{}).get(tr,0)
def tot(d): return sum(mins.get(d,{}).values())

# ---- daily lanes (design, adjusted) ----
ex=EX0[:]; em=EM0[:]
ex[25]=0                       # Fri Aug 28 is an empty heat cell
# last 2 weeks: table/home/dots (i 70..81 = Oct 12..23)
ex[70:82]=[0,0,0,1,0,1,1,1,1,1,1,0]
em[70:82]=[0,1,1,1,0,0,0,1,1,1,1,0]
for i in range(70):            # older days: hits 45/30
    if ex[i]: setm(day(i),'ex',45)
    if em[i]: setm(day(i),'em',30)

# ---- this week (Mon 19 .. Fri 23), fixed ----
TW={ 'dw':[252,306,228,360,223],'ex':[50,45,50,50,30],'em':[40,30,42,40,27],
     'mt':[90,0,50,130,54],'rd':[45,0,0,45,0]}
for t,v in TW.items():
    for k,m in enumerate(v): setm(day(77+k),t,m)
# ---- last week (Mon 12 .. Sun 18), fixed ----
LW={ 'dw':[350,360,60,60,50,290,0],'ex':[15,0,15,45,15,45,45],'em':[20,30,30,30,20,20,20],
     'mt':[0,0,120,120,95,0,35],'rd':[0,0,0,0,0,42,0]}
for t,v in LW.items():
    for k,m in enumerate(v): setm(day(70+k),t,m)

def level_of(d):
    j=(d-D0).days; return HEAT[j]
WANT_LEVEL={}                  # deliberate heat deviations
WANT_LEVEL[dt.date(2026,9,18)]=1   # lanes keep Ex+Em (best runs) -> low, not empty
WANT_LEVEL[dt.date(2026,9,11)]=2   # week of Sep 7 needs capacity for its 73px trend bar
WANT_LEVEL[dt.date(2026,10,22)]=3  # Thu 6:00 DW + Ex streak -> perfect
WANT_LEVEL[dt.date(2026,10,23)]=2  # today in progress
def want(d): return WANT_LEVEL.get(d, level_of(d))
def band(d):
    v=want(d)
    lo={0:0,1:E0*T,2:E1*T,3:T}[v]; hi={0:E0*T,1:E1*T,2:T,3:10**6}[v]
    import math
    return (0 if v==0 else math.ceil(lo+1e-9), math.ceil(hi)-1)

# ---- weekly fill plans for older weeks: (dw, mt, rd) minutes ----
PLAN={
  # idx: (dw, mt, rd)
  0:(None,480,30), 1:(None,0,180), 2:(None,0,180), 3:(None,480,40),
  4:(1010,None,173), 5:(1100,None,173), 6:(1025,None,0), 7:(1235,None,0), 8:(1145,None,0), 9:(1280,None,0),
}
WEEKTOT={4:1466,5:1671,6:1602,7:1807,8:1716,9:1876}
def fill_week(k):
    days=[day(7*k+d) for d in range(7)]
    for d in days: mins.setdefault(d,{t:0 for t in TR})
    dwT,mtT,rdT=PLAN[k]
    lanes=sum(tot(d) for d in days)
    if k in WEEKTOT:
        rest=WEEKTOT[k]-dwT-lanes-rdT
        mtT=rest
    caps=[]
    for d in days:
        lo,hi=band(d); caps.append([lo,hi])
    if dwT is None:   # free week: fill DW to ~60% of the remaining capacity
        room=sum(max(0,min(hi,2000)-tot(d)) for d,(lo,hi) in zip(days,caps))
        dwT=max(0,int((room-mtT-rdT)*0.7))
    need={'dw':dwT,'mt':mtT,'rd':rdT}
    order=['rd','mt','dw']
    # 1) reach each day's lower bound
    for d,(lo,hi) in zip(days,caps):
        for t in (['dw','mt','rd'] if d.weekday()<5 else ['rd','mt','dw']):
            short=lo-tot(d)
            if short<=0: break
            if need[t]<=0: continue
            a=min(short,need[t]); setm(d,t,getm(d,t)+a); need[t]-=a
    # 2) distribute the rest: green days first, then mids, then lows
    pri=sorted(range(7),key=lambda x:(-want(days[x]),x))
    for t in ['rd','mt','dw']:
        # spread rd/mt across days evenly where room
        while need[t]>0:
            moved=False
            for x in pri:
                d=days[x]; lo,hi=caps[x]
                room=hi-tot(d)
                if room<=0 or want(d)==0: continue
                if room<5 and need[t]>room: continue
                chunk={'rd':30,'mt':30,'dw':60}[t]
                a=min(chunk,room,need[t])
                if a<=0: continue
                setm(d,t,getm(d,t)+a); need[t]-=a; moved=True
                if need[t]<=0: break
            if not moved: break
    if any(v>0 for v in need.values()): print("WEEK",k,"UNPLACED",need, file=sys.stderr)
for k in range(10): fill_week(k)
# Sun Aug 2 (heat low): a little reading
setm(D0,'rd',60)

# ---- Reading before Aug 2: Saturdays from Jan 3 so YTD = 96:10 (5770) ----
ytd=sum(getm(d,'rd') for d in list(mins) if d.year==2026)
rest=5770-ytd
sats=[dt.date(2026,1,3)+dt.timedelta(7*n) for n in range(30)]
for n,s in enumerate(sats):
    setm(s,'rd',rest//30+(1 if n<rest%30 else 0))
json.dump({d.isoformat():v for d,v in sorted(mins.items())},open('days.json','w'))
