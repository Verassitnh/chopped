import sys; sys.path.insert(0,'/tmp/pocus-gen/c3')
ICONS={
 'target':'<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.2" fill="{c}"/>',
 'people':'<circle cx="9" cy="8" r="3.2"/><path d="M3 19c0-3.3 2.7-5.5 6-5.5s6 2.2 6 5.5"/><circle cx="16.5" cy="9" r="2.6"/><path d="M16.8 13.6c2.5.2 4.2 2 4.2 4.4"/>',
 'pulse':'<path d="M2.5 12h4l2.5-6.5 4.5 13 2.5-6.5h5.5"/>',
 'mail':'<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3.8 6.6 12 12.8l8.2-6.2"/>',
 'book':'<path d="M12 6.5C10 5 7 4.5 3.5 5v13c3.5-.5 6.5 0 8.5 1.5 2-1.5 5-2 8.5-1.5V5C17 4.5 14 5 12 6.5Z"/><path d="M12 6.5v13"/>'}
A="#4A8BE5"; RGB="74,139,229"; TINT="#172335"
def ic(k,size=36,r=11,g=18,stroke="#000000",bg="rgba(0,0,0,0.13)"):
    return f'<div layer-name="Icon" style="width:{size}px;height:{size}px;border-radius:{r}px;background:{bg};display:flex;align-items:center;justify-content:center;flex-shrink:0;"><svg width="{g}" height="{g}" viewBox="0 0 24 24" fill="none" stroke="{stroke}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{ICONS[k].format(c=stroke)}</svg></div>'
def tx(t,f="Geist",s=13,w=500,c="#8E8E93",ls=None,lh=None,extra=""):
    lh=lh or s+4; l=f"letter-spacing:{ls};" if ls else ""
    return f'<div style="font-family:{f};font-size:{s}px;font-weight:{w};line-height:{lh}px;{l}color:{c};{extra}">{t}</div>'
def mono(t,s,c,w=500,ls="-0.05em",extra=""): return tx(t,"Geist Mono",s,w,c,ls,None,extra)
def stop(s=56,sq=None,bg="#000000",c=A):
    sq=sq or round(s*.3); return f'<div layer-name="Stop" style="width:{s}px;height:{s}px;border-radius:{s//2}px;background:{bg};display:flex;align-items:center;justify-content:center;flex-shrink:0;"><div style="width:{sq}px;height:{sq}px;border-radius:4px;background:{c};"></div></div>'
def segs(p,h=6,on=A,off=f"rgba({RGB},0.2)",n=20,extra=""):
    k=round(p*n); return f'<div layer-name="Goal ticks" style="display:flex;gap:3px;{extra}">'+''.join(f'<div style="flex:1;height:{h}px;border-radius:2px;background:{on if i<k else off};"></div>' for i in range(n))+'</div>'
def row(*a,gap=12,al="center",jc="space-between",extra=""): return f'<div style="display:flex;align-items:{al};justify-content:{jc};gap:{gap}px;{extra}">'+''.join(a)+'</div>'
def col(*a,gap=4,extra=""): return f'<div style="display:flex;flex-direction:column;gap:{gap}px;{extra}">'+''.join(a)+'</div>'
def dot(c=A,s=7): return f'<div style="width:{s}px;height:{s}px;border-radius:{s}px;background:{c};flex-shrink:0;"></div>'
DAYS=[("M","4:12",252),("T","5:06",306),("W","3:48",228),("T","6:00",360),("F","3:43",223),("S","–",0),("S","–",0)]
def week(maxh=64,past=f"rgba({RGB},0.38)",today=A,lab="#6C6C70",val="#6C6C70",todayc="#FFFFFF",empty=f"rgba({RGB},0.14)",barw=None):
    out=[]
    for i,(d,v,m) in enumerate(DAYS):
        t=i==4; h=round(m/360*maxh) if m else 4
        bg=today if t else (past if m else empty)
        w=f"width:{barw}px;" if barw else "align-self:stretch;"
        out.append(f'<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:8px;">{mono(v,11,todayc if t else val,600 if t else 500,"-0.02em")}<div style="{w}height:{h}px;border-radius:{6 if m else 2}px;background:{bg};"></div>{mono(d,12,todayc if t else lab,700 if t else 500,"0")}</div>')
    return f'<div layer-name="Week" style="display:flex;align-items:flex-end;gap:8px;">'+''.join(out)+'</div>'
H=lambda name,body: f'<div layer-name="{name}" style="display:flex;flex-direction:column;">{body}</div>'
STATUS='<x-paper-clone node-id="33E-0" />'; NAV='<x-paper-clone node-id="336-0" />'
ENTRIES='<x-paper-clone node-id="301-0" />'; SETTINGS='<x-paper-clone node-id="2ZA-0" />'; DELETE='<x-paper-clone node-id="2Z8-0" />'
def wrap(inner,pad="8px 12px 0"): return f'<div style="display:flex;flex-direction:column;padding:{pad};">{inner}</div>'

def d1():
    hero=f'''<div layer-name="Hero — running" style="display:flex;flex-direction:column;gap:14px;padding:14px 4px 18px;border-radius:28px;background:{TINT};">
{row(row(dot(),tx("Clocked in · 20:06",s=13,w=600,c="#AEAEB2"),gap=7,jc="flex-start"),mono("Resets Mon",12,"#6C6C70",ls="-0.02em"),extra="padding:0 18px;")}
<div style="display:flex;align-items:center;gap:12px;padding:18px;border-radius:24px;background:{A};">{col(row(ic("target",34,10,17),col(tx("Deep Work","Geist",22,650,"#000000","-0.02em",26),tx("Weekly · 25h goal",s=13,c="rgba(0,0,0,0.62)"),gap=0),gap=10,jc="flex-start"),mono("00:50:01",58,"#000000",extra="line-height:62px;"),gap=8,extra="flex:1;")}{stop(60)}</div>
{col(row(row(mono("22:49",17,"#FFFFFF"),mono("of 25h",13,"#8E8E93",ls="-0.02em"),gap=6,al="baseline",jc="flex-start"),tx("2h 11m left",s=13,c="#8E8E93")),segs(.91,7),gap=10,extra="padding:0 18px;")}
</div>'''
    wk=f'<div layer-name="This week" style="display:flex;flex-direction:column;gap:16px;padding:20px 18px 16px;border-radius:26px;background:#141416;">{row(tx("This week",s=15,w=600,c="#F2F2F7"),mono("avg 4:34",13,"#8E8E93",ls="-0.02em"))}{week()}</div>'
    return [STATUS,NAV,wrap(hero),wrap(wk,"28px 12px 0"),ENTRIES,SETTINGS,DELETE]
def d2():
    tic=ic("target",40,12,20,stroke=A,bg=f"rgba({RGB},0.18)")
    hero=f'''<div layer-name="Hero — tinted" style="display:flex;flex-direction:column;gap:22px;padding:20px 4px 4px;border-radius:28px;background:{TINT};">
<div style="display:flex;flex-direction:column;gap:18px;padding:0 16px;">{row(tic,col(tx("Deep Work","Geist",22,650,"#F2F2F7","-0.02em",26),tx("Weekly · 25h goal · resets Mon",s=13,c="#8E8E93"),gap=1,extra="flex:1;"),gap=12,jc="flex-start")}
{col(row(dot(),tx("Clocked in · 20:06",s=13,w=600,c="#AEAEB2"),gap=7,jc="flex-start"),mono("00:50:01",64,"#FFFFFF",extra="line-height:68px;"),gap=6)}
{col(segs(.91,7),row(row(mono("22:49",15,"#FFFFFF"),mono("/25:00",12,"#6C6C70",ls="-0.02em"),gap=3,al="baseline",jc="flex-start"),tx("2h 11m left",s=13,c="#8E8E93")),gap=10)}</div>
<div layer-name="Stop button" style="display:flex;align-items:center;justify-content:center;gap:10px;height:60px;border-radius:24px;background:{A};"><div style="width:16px;height:16px;border-radius:4px;background:#000000;"></div>{tx("Stop","Geist",17,650,"#000000")}</div>
</div>'''
    wk=f'<div layer-name="This week" style="display:flex;flex-direction:column;gap:18px;padding:36px 28px 0;">{row(tx("This week",s=15,w=600,c="#F2F2F7"),mono("avg 4:34",13,"#8E8E93",ls="-0.02em"))}{week()}</div>'
    return [STATUS,NAV,wrap(hero),wk,ENTRIES,SETTINGS,DELETE]
def d3():
    hero=f'''<div layer-name="Hero — week in strip" style="display:flex;flex-direction:column;gap:16px;padding:4px 4px 16px;border-radius:28px;background:{TINT};">
<div style="display:flex;flex-direction:column;gap:14px;padding:18px;border-radius:24px;background:{A};">
{row(row(ic("target",34,10,17),col(tx("Deep Work","Geist",20,650,"#000000","-0.02em",24),tx("Clocked in · 20:06",s=13,c="rgba(0,0,0,0.62)"),gap=0),gap=10,jc="flex-start"),stop(52))}
{mono("00:50:01",58,"#000000",extra="line-height:62px;")}
{col(segs(.91,6,on="#000000",off="rgba(0,0,0,0.16)"),row(row(mono("22:49",14,"#000000"),mono("of 25h",12,"rgba(0,0,0,0.55)",ls="-0.02em"),gap=5,al="baseline",jc="flex-start"),tx("2h 11m left",s=12,c="rgba(0,0,0,0.55)")),gap=8)}
</div>
<div style="padding:4px 18px 0;">{week(48,past=f"rgba({RGB},0.45)",empty=f"rgba({RGB},0.18)",lab="#8E8E93",val="#6C6C70")}</div>
</div>'''
    return [STATUS,NAV,wrap(hero),ENTRIES,SETTINGS,DELETE]
def d4():
    hero=f'''<div layer-name="Hero — running" style="display:flex;flex-direction:column;gap:12px;padding:12px 4px 14px;border-radius:26px;background:{TINT};">
{row(row(dot(),tx("Clocked in · 20:06",s=13,w=600,c="#AEAEB2"),gap=7,jc="flex-start"),mono("22:49 of 25h",12,"#8E8E93",ls="-0.02em"),extra="padding:0 18px;")}
<div style="display:flex;align-items:center;gap:12px;padding:14px;border-radius:22px;background:{A};">{col(row(ic("target",30,9,16),tx("Deep Work","Geist",20,600,"#000000","-0.015em",24),gap=10,jc="flex-start"),mono("00:50:01",50,"#000000",extra="line-height:54px;"),gap=4,extra="flex:1;")}{stop(56)}</div>
{segs(.91,6,extra="margin:0 18px;")}</div>'''
    def sec(name,head,body,pb=14):
        return f'<div layer-name="{name}" style="display:flex;flex-direction:column;gap:14px;padding:4px 4px {pb}px;border-radius:26px;background:#141416;"><div style="display:flex;align-items:center;justify-content:space-between;padding:14px;border-radius:22px;background:#202023;">{head}</div><div style="padding:0 18px;">{body}</div></div>'
    wk=sec("This week",tx("This week",s=15,w=600,c="#F2F2F7")+row(mono("22:49",16,"#FFFFFF"),mono("/25:00",12,"#6C6C70",ls="-0.02em"),gap=3,al="baseline"),week(52),16)
    def ent(a,b,live=False):
        return row(mono(a,16,"#C8C8C8",400,"-0.03em"),row(dot() if live else "",mono(b,16,"#C8C8C8" if live else "#6C6C70",500,"-0.03em"),gap=8),extra="height:46px;")
    def day(d,t): return row(tx(d,s=12,w=600,c="#6C6C70",extra="text-transform:uppercase;letter-spacing:0.04em;"),mono(t,12,"#6C6C70",ls="-0.02em"),extra="padding-top:10px;height:28px;")
    add='<div style="display:flex;align-items:center;gap:6px;height:30px;padding:0 12px;border-radius:16px;background:rgba(255,255,255,0.08);"><svg width="11" height="11" viewBox="0 0 12 12" fill="none"><path d="M6 1v10M1 6h10" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/></svg>'+tx("Add",s=13,w=600,c="#CFCFCF")+'</div>'
    en=sec("Entries",tx("Entries",s=15,w=600,c="#F2F2F7")+add,col(day("Today","7:20"),ent("20:06 → now","0:50",True),ent("13:30 → 16:15","2:45"),ent("09:00 → 12:45","3:45"),day("Thursday","6:00"),ent("14:00 → 17:45","3:45"),ent("09:30 → 11:45","2:15"),gap=0),8)
    return [STATUS,NAV,wrap(hero),wrap(wk,"14px 12px 0"),wrap(en,"14px 12px 0"),SETTINGS,DELETE]
def d5():
    hero=f'''<div layer-name="Hero — compact" style="display:flex;flex-direction:column;gap:12px;padding:4px 4px 14px;border-radius:26px;background:{TINT};">
<div style="display:flex;align-items:center;gap:12px;padding:12px 12px 12px 14px;border-radius:22px;background:{A};">{ic("target",36,11,18)}{col(tx("Deep Work","Geist",18,600,"#000000","-0.015em",22),tx("Since 20:06",s=13,c="rgba(0,0,0,0.62)"),gap=1,extra="flex:1;")}{mono("0:50:01",30,"#000000")}{stop(46)}</div>
{col(row(tx("Weekly · 25h goal",s=13,c="#8E8E93"),row(mono("22:49",13,"#FFFFFF",ls="-0.02em"),mono("/25:00",12,"#6C6C70",ls="-0.02em"),gap=2,al="baseline")),segs(.91,5),gap=8,extra="padding:0 18px;")}</div>'''
    def stat(v,l,c="#F2F2F7"): return col(mono(v,24,c),tx(l,s=12,c="#6C6C70"),gap=2,extra="flex:1;")
    trio=f'<div layer-name="Numbers" style="display:flex;padding:28px 30px 0;">{stat("3:43","Today")}{stat("22:49","This week")}{stat("5w","Streak",A)}</div>'
    wk=f'<div layer-name="This week" style="display:flex;flex-direction:column;padding:28px 28px 0;">{week(56)}</div>'
    return [STATUS,NAV,wrap(hero),trio,wk,ENTRIES,SETTINGS,DELETE]
for k,f in enumerate([d1,d2,d3,d4,d5],1):
    open(f'/tmp/pocus-gen/d/d{k}.html','w').write(''.join(f()))
    print(k,len(''.join(f())))
