# column-major (Sun..Sat), 12 cols starting Sun Aug 2 2026; last cell (Sat Oct 24) future = -1
cols = [
 "1111111","2101111","1210122","2201202","1120222","2210212",
 "1322202","2232332","2223222","3322332","3332223","232223-",
]
L=[]
for c in cols:
    for ch in c: L.append(-1 if ch=='-' else int(ch))
if __name__=="__main__":
    import datetime as dt
    d=dt.date(2026,8,2)
    print(len(L), sum(1 for v in L if v==3))
    for i,v in enumerate(L):
        if v in (0,3): print(d+dt.timedelta(i), d.__class__, v) if False else print((d+dt.timedelta(i)).strftime("%a %b %d"), v)
