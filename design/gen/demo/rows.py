"""Print the DemoData.swift `days` table from days.json (+ Reading Saturdays Jan 3 → Jul 25 so YTD = 96:10)."""
import json, datetime as dt
J=json.load(open('days.json'))
M={dt.date.fromisoformat(k):v for k,v in J['days'].items()}
W0=dt.date(2026,8,3); TODAY=dt.date(2026,10,23)
post={W0+dt.timedelta(7*int(k)+4):v for k,v in J['post'].items()}
rest=5770-sum(v['rd'] for v in M.values())
for n in range(30):
    M[dt.date(2026,1,3)+dt.timedelta(7*n)]={'dw':0,'mt':0,'ex':0,'em':0,'rd':rest//30+(1 if n<rest%30 else 0)}
cells=[]
for d in sorted(M):
    v=M[d]; p=post.get(d,{'dw':0,'mt':0})
    if d>=dt.date(2026,10,19): v=dict(v,dw=0)       # this week's Deep Work is added as real sessions
    cells.append(f"({d.month}, {d.day}, {v['dw']}, {v['mt']}, {v['ex']}, {v['em']}, {v['rd']}, {p['dw']}, {p['mt']})")
for i in range(0,len(cells),4): print('        '+', '.join(cells[i:i+4])+',')
