def tx(t,f="Geist",s=13,w=500,c="#8E8E93",ls=None,lh=None,extra=""):
    lh=lh or s+4; l=f"letter-spacing:{ls};" if ls else ""
    return f'<div style="font-family:{f};font-size:{s}px;font-weight:{w};line-height:{lh}px;{l}color:{c};white-space:nowrap;{extra}">{t}</div>'
def mono(t,s,c="#F2F2F7",w=500,ls="-0.04em",extra=""): return tx(t,"Geist Mono",s,w,c,ls,None,extra)
def pixel(t,s,c="#FFFFFF",extra=""): return tx(t,"Geist Pixel",s,400,c,"0em",s,extra)
def lab(t,c="#6C6C70"): return tx(t.upper(),"Geist Mono",11,500,c,"0.08em",14)
def row(*a,gap=12,al="center",jc="space-between",extra=""): return f'<div style="display:flex;align-items:{al};justify-content:{jc};gap:{gap}px;{extra}">'+''.join(a)+'</div>'
def col(*a,gap=4,extra=""): return f'<div style="display:flex;flex-direction:column;gap:{gap}px;{extra}">'+''.join(a)+'</div>'
def dot(c,s=8,extra=""): return f'<div style="width:{s}px;height:{s}px;border-radius:{s}px;background:{c};flex-shrink:0;{extra}"></div>'
def sec(name,body,pt=48): return f'<div layer-name="{name}" style="display:flex;flex-direction:column;padding:{pt}px 20px 0;">{body}</div>'
UP="#39D353"; DOWN="#8E8E93"
T=[dict(n="Deep Work",c="#4A8BE5",rgb="74,139,229",w="22:49",l="19:30",d="+3:19",up=1,per="Week",g="22:49 / 25:00",p=.91,hr="8/11",hu="weeks",pct="73%",best="5",st="5w",hist=[0,1,0,1,1,0,1,1,1,1,1,2],mins=1369),
   dict(n="Meetings",c="#F7A23A",rgb="247,162,58",w="5:24",l="6:10",d="−0:46",up=0,per="Week",g="5:24 / 8:00",p=.68,hr="9/11",hu="weeks",pct="82%",best="4",st="4w",hist=[1,1,0,1,1,1,0,1,1,1,1,2],mins=324),
   dict(n="Exercise",c="#1DB3A6",rgb="29,179,166",w="3:45",l="3:00",d="+0:45",up=1,per="Today",g="0:30 / 0:45",p=.67,hr="58/82",hu="days",pct="71%",best="21",st="6d",hist=[0,0,0,1,0,0,1,1,1,1,1,2],mins=225),
   dict(n="Email",c="#9D68F0",rgb="157,104,240",w="2:59",l="2:50",d="+0:09",up=1,per="Today",g="0:27 / 0:30",p=.90,hr="67/82",hu="days",pct="82%",best="17",st="12d",hist=[0,1,1,1,0,0,1,1,1,1,1,2],mins=179),
   dict(n="Reading",c="#EF6B6B",rgb="239,107,107",w="1:30",l="0:42",d="+0:48",up=1,per="Year",g="96:10 / 150:00",p=.64,hr="9/12",hu="on pace",pct="75%",best="4",st="4w",hist=[0,1,1,0,1,1,1,0,1,1,1,1],mins=90)]
TOTAL="36:27"; LAST="32:12"; DELTA="+4:15"; DPCT="+13%"; TM=2187
WEEKS=[("AUG 30",1450),("SEP 6",1660),("SEP 13",1565),("SEP 20",1770),("SEP 27",1695),("OCT 4",1850),("OCT 11",1932),("NOW",2187)]
STATUS='<x-paper-clone node-id="3FT-0" />'; TAB='<x-paper-clone node-id="33P-0" />'
CHART='<x-paper-clone node-id="3CV-0" />'; HEAT='<x-paper-clone node-id="35L-0" />'; STREAK='<x-paper-clone node-id="33Z-0" />'
SPACER='<div style="height:120px;"></div>'
def header(sub="Oct 19 – 25"):
    per=''.join(tx(p,"Geist Mono",12,600 if p=="W" else 500,"#FFFFFF" if p=="W" else "#5E5E62","0.04em",16,extra=("padding:6px 10px;border-radius:12px;background:rgba(255,255,255,0.10);" if p=="W" else "padding:6px 10px;")) for p in ["W","M","6M","Y"])
    return f'<div layer-name="Header" style="display:flex;align-items:flex-end;justify-content:space-between;padding:12px 20px 0;">{col(lab(sub),tx("Stats","Geist",34,700,"#F2F2F7","-0.03em",40),gap=4)}<div style="display:flex;gap:2px;padding-bottom:4px;">{per}</div></div>'
def segs(p,c,rgb,n=20,h=4,gap=2):
    return f'<div style="display:flex;height:{h}px;border-radius:{h}px;background:rgba({rgb},0.18);"><div style="width:{p*100:.0f}%;height:{h}px;border-radius:{h}px;background:{c};"></div></div>'
def hist(t,shape="dot",s=8,gap=6,flex=False):
    out=[]
    for v in t["hist"]:
        if v==2: st=f"border:1.5px dashed {t['c']};background:transparent;"
        elif v: st=f"background:{t['c']};"
        else: st=f"background:rgba({t['rgb']},0.18);"
        r=s if shape=="dot" else 3
        size=f"flex:1;height:{s}px;" if flex else f"width:{s}px;height:{s}px;"
        out.append(f'<div style="{size}border-radius:{r}px;box-sizing:border-box;{st}"></div>')
    return f'<div style="display:flex;gap:{gap}px;align-items:center;{"width:100%;" if flex else ""}">'+''.join(out)+'</div>'
def delta(t,s=13): return mono(("↑ " if t["up"] else "↓ ")+t["d"].lstrip("+−"),s,UP if t["up"] else DOWN,ls="-0.02em")

# ---------- S1  Delta first ----------
def s1():
    hero=col(lab("This week"),row(pixel(TOTAL,112),gap=0,jc="flex-start"),row(mono("↑ "+DELTA.lstrip("+"),17,UP,ls="-0.02em"),mono(f"{DPCT} vs last week · {LAST}",13,"#6C6C70",ls="-0.02em"),gap=10,jc="flex-start",al="baseline"),gap=10)
    rows=''.join(f'<div layer-name="{t["n"]}" style="display:flex;flex-direction:column;gap:10px;padding:16px 0;">{row(row(dot(t["c"]),tx(t["n"],s=16,w=600,c="#F2F2F7"),gap=10,jc="flex-start"),row(delta(t),mono(t["w"],20),gap=14),gap=12)}<div style="height:3px;border-radius:2px;background:#1A1A1C;display:flex;"><div style="width:{t["mins"]/TM*100:.1f}%;height:3px;border-radius:2px;background:{t["c"]};"></div></div></div>' for t in T)
    goals=''.join(f'<div style="display:flex;flex-direction:column;gap:8px;">{row(tx(t["n"],s=13,c="#AEAEB2"),row(mono(t["per"].upper(),11,"#5E5E62",ls="0.06em"),mono(t["g"],13,"#AEAEB2",ls="-0.02em"),gap=8),gap=8)}{segs(t["p"],t["c"],t["rgb"])}</div>' for t in T)
    hits=''.join(f'<div style="display:flex;align-items:center;gap:14px;padding:12px 0;"><div style="width:92px;">{tx(t["n"],s=13,c="#AEAEB2")}</div><div style="flex:1;">{hist(t,"dot",9,7)}</div>{row(mono(t["hr"].split("/")[0],15,"#F2F2F7"),mono("/"+t["hr"].split("/")[1],12,"#5E5E62",ls="-0.02em"),gap=0,al="baseline")}</div>' for t in T)
    return [STATUS,header(),sec("Total",hero,36),sec("By tracker",col(lab("Hours by tracker"),f'<div style="display:flex;flex-direction:column;">{rows}</div>',gap=6),44),
            sec("Goal pace",col(row(lab("Goal pace"),mono("4/5 on pace",12,"#AEAEB2",ls="-0.02em")),col(*[goals],gap=18),gap=18),40),CHART,
            sec("Hit history",col(row(lab("Goals hit · last 12"),mono("best streak",11,"#5E5E62",ls="0.04em")),f'<div style="display:flex;flex-direction:column;">{hits}</div>',gap=8),48),HEAT,STREAK,SPACER,TAB]

# ---------- S2  Stacked bars + ledger ----------
def s2():
    def stack(field,h):
        tot=sum(t["mins"] if field=="w" else int(t["l"].split(":")[0])*60+int(t["l"].split(":")[1]) for t in T)
        parts=[]
        for t in T:
            m=t["mins"] if field=="w" else int(t["l"].split(":")[0])*60+int(t["l"].split(":")[1])
            parts.append(f'<div style="width:{m/2187*100:.2f}%;height:{h}px;background:{t["c"] if field=="w" else f"rgba({t["rgb"]},0.35)"};"></div>')
        return f'<div style="display:flex;gap:2px;border-radius:4px;overflow:hidden;">'+''.join(parts)+'</div>'
    hero=row(col(lab("This week"),pixel(TOTAL,104),gap=8),col(mono(DELTA,22,UP),mono(DPCT,13,"#6C6C70",ls="-0.02em"),gap=2,extra="align-items:flex-end;padding-bottom:12px;"),al="flex-end")
    bars=col(row(stack("w",14),gap=0,extra="display:block;"),row(mono("THIS WEEK",10,"#6C6C70",ls="0.08em"),mono(TOTAL,11,"#AEAEB2",ls="-0.02em")),
             f'<div style="height:6px;"></div>',stack("l",8),row(mono("LAST WEEK",10,"#5E5E62",ls="0.08em"),mono(LAST,11,"#6C6C70",ls="-0.02em")),gap=6)
    th=lambda t,w,al="right": f'<div style="width:{w}px;text-align:{al};">{mono(t,10,"#5E5E62",ls="0.08em",extra=f"text-align:{al};")}</div>'
    td=lambda v,w,c="#F2F2F7",s=15: f'<div style="width:{w}px;display:flex;justify-content:flex-end;">{mono(v,s,c,ls="-0.02em")}</div>'
    head=f'<div style="display:flex;align-items:center;padding-bottom:10px;border-bottom:1px solid #1C1C1E;"><div style="flex:1;">{mono("TRACKER",10,"#5E5E62",ls="0.08em")}</div>{th("NOW",64)}{th("LAST",58)}{th("Δ",62)}</div>'
    body=''.join(f'<div style="display:flex;align-items:center;height:48px;border-bottom:1px solid #161618;"><div style="flex:1;display:flex;align-items:center;gap:10px;">{dot(t["c"],7)}{tx(t["n"],s=15,w=500,c="#E5E5EA")}</div>{td(t["w"],64)}{td(t["l"],58,"#5E5E62")}{td(t["d"],62,UP if t["up"] else DOWN,13)}</div>' for t in T)
    foot=f'<div style="display:flex;align-items:center;height:48px;"><div style="flex:1;">{mono("TOTAL",11,"#AEAEB2",ls="0.08em")}</div>{td(TOTAL,64,"#FFFFFF",16)}{td(LAST,58,"#5E5E62")}{td(DELTA,62,UP,13)}</div>'
    ledger=f'<div style="display:flex;flex-direction:column;">{head}{body}{foot}</div>'
    goal=''.join(f'<div style="display:flex;flex-direction:column;gap:6px;">{row(tx(t["n"],s=12,c="#8E8E93"),mono(f"{round(t["p"]*100)}%",12,"#AEAEB2",ls="-0.02em"))}{segs(t["p"],t["c"],t["rgb"],10,6,3)}</div>' for t in T)
    goalgrid=f'<div style="display:grid;grid-template-columns:1fr 1fr;gap:18px 24px;">{goal}</div>'
    goalgrid='<div style="display:flex;flex-wrap:wrap;gap:18px 24px;">'+''.join(f'<div style="width:184px;">{g}</div>' for g in [f'<div style="display:flex;flex-direction:column;gap:6px;">{row(tx(t["n"],s=12,c="#8E8E93"),mono(f"{round(t["p"]*100)}%",12,"#AEAEB2",ls="-0.02em"))}{segs(t["p"],t["c"],t["rgb"],10,6,3)}<div>{mono(t["per"].upper()+" "+t["g"],10,"#5E5E62",ls="0.02em")}</div></div>' for t in T])+'</div>'
    hits=''.join(f'<div style="display:flex;flex-direction:column;gap:8px;padding:12px 0;">{row(tx(t["n"],s=13,c="#AEAEB2"),row(mono(t["pct"],13,"#F2F2F7",ls="-0.02em"),mono(t["st"],12,t["c"],ls="-0.02em"),gap=10))}{hist(t,"sq",14,3,flex=True)}</div>' for t in T)
    return [STATUS,header(),sec("Total",hero,36),sec("Split",bars,24),sec("Ledger",ledger,36),sec("Goal pace",col(row(lab("Goal pace"),mono("4/5 on pace",12,"#AEAEB2",ls="-0.02em")),goalgrid,gap=18),44),CHART,
            sec("Hit history",col(lab("Hit rate · current streak"),f'<div style="display:flex;flex-direction:column;">{hits}</div>',gap=8),48),HEAT,STREAK,SPACER,TAB]

# ---------- S3  Trend first ----------
def s3():
    mx=2187
    bars=''.join(f'<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:8px;">{mono(f"{m//60}:{m%60:02d}" if i in (6,7) else "",10,"#FFFFFF" if i==7 else "#6C6C70",ls="-0.02em")}<div style="align-self:stretch;height:{round(m/mx*110)}px;border-radius:4px;background:{"#F2F2F7" if i==7 else "#2A2A2D"};"></div>{mono(d,9,"#FFFFFF" if i==7 else "#5E5E62",ls="0.04em")}</div>' for i,(d,m) in enumerate(WEEKS))
    hero=col(row(col(lab("This week"),pixel(TOTAL,96),gap=8),col(mono(DELTA,18,UP),mono("vs 32:12",12,"#6C6C70",ls="-0.02em"),gap=2,extra="align-items:flex-end;padding-bottom:8px;"),al="flex-end"),
             f'<div layer-name="8-week trend" style="display:flex;align-items:flex-end;gap:8px;padding-top:20px;">{bars}</div>',row(mono("8-WEEK AVG 29:42",10,"#5E5E62",ls="0.06em"),mono("BEST WEEK",10,"#AEAEB2",ls="0.06em")),gap=12)
    trk=''.join(f'<div layer-name="{t["n"]}" style="display:flex;flex-direction:column;gap:12px;padding:18px 0;border-top:1px solid #161618;">{row(row(dot(t["c"]),tx(t["n"],s=16,w=600,c="#F2F2F7"),gap=10,jc="flex-start"),row(mono(t["w"],20),delta(t,12),gap=10,al="baseline"))}{segs(t["p"],t["c"],t["rgb"],20,5,2)}{row(mono(t["per"].upper()+" GOAL "+t["g"],10,"#5E5E62",ls="0.04em"),mono(f"HIT {t["hr"]} · {t["st"]}",10,"#8E8E93",ls="0.04em"))}</div>' for t in T)
    return [STATUS,header(),sec("Total + trend",hero,36),sec("Trackers",col(row(lab("By tracker"),mono("4/5 on pace",12,"#AEAEB2",ls="-0.02em")),f'<div style="display:flex;flex-direction:column;padding-top:8px;">{trk}</div>',gap=4),44),CHART,HEAT,STREAK,SPACER,TAB]

# ---------- S4  Receipt / indexed ----------
def s4():
    lead=lambda: '<div style="flex:1;height:1px;border-bottom:1px dotted #3A3A3C;margin:0 8px;align-self:center;"></div>'
    line=lambda a,b,ac="#AEAEB2",bc="#F2F2F7",s=14: f'<div style="display:flex;align-items:baseline;height:30px;">{mono(a,s,ac,ls="0em")}{lead()}{mono(b,s,bc,ls="-0.02em")}</div>'
    hero=col(row(lab("Week 43 · Oct 19–25"),lab("Receipt")),f'<div style="display:flex;align-items:baseline;justify-content:space-between;padding:6px 0 4px;">{pixel(TOTAL,96)}<div style="display:flex;flex-direction:column;align-items:flex-end;gap:2px;">{mono(DELTA,16,UP)}{mono(DPCT,12,"#6C6C70",ls="-0.02em")}</div></div>',gap=6)
    items=''.join(f'<div style="display:flex;align-items:baseline;height:34px;">{mono(f"0{i+1}",12,"#5E5E62",ls="0em",extra="width:28px;")}{dot(t["c"],6,"margin-right:8px;align-self:center;")}{tx(t["n"],s=15,w=500,c="#E5E5EA")}{lead()}{mono(t["d"],12,UP if t["up"] else DOWN,ls="-0.02em",extra="width:52px;text-align:right;")}{mono(t["w"],15,"#F2F2F7",ls="-0.02em",extra="width:56px;text-align:right;")}</div>' for i,t in enumerate(T))
    tot=f'<div style="border-top:1px dashed #3A3A3C;margin-top:8px;padding-top:8px;">{line("TOTAL",TOTAL,"#F2F2F7","#FFFFFF",15)}{line("LAST WEEK",LAST,"#6C6C70","#6C6C70",13)}{line("CHANGE",DELTA+"  "+DPCT,"#6C6C70",UP,13)}</div>'
    th=lambda t,w: mono(t,10,"#5E5E62",ls="0.08em",extra=f"width:{w}px;text-align:right;")
    gh=f'<div style="display:flex;align-items:center;padding-bottom:8px;border-bottom:1px solid #1C1C1E;">{mono("#",10,"#5E5E62",ls="0.08em",extra="width:28px;")}<div style="flex:1;">{mono("GOAL",10,"#5E5E62",ls="0.08em")}</div>{th("PACE",56)}{th("HIT",56)}{th("RATE",48)}{th("STRK",48)}</div>'
    gr=''.join(f'<div style="display:flex;align-items:center;height:44px;border-bottom:1px solid #141416;">{mono(f"0{i+1}",12,"#5E5E62",ls="0em",extra="width:28px;")}<div style="flex:1;display:flex;flex-direction:column;gap:5px;padding-right:12px;">{mono(t["per"].upper()+" "+t["g"].split(" / ")[1],10,"#6C6C70",ls="0.04em")}{segs(t["p"],t["c"],t["rgb"],12,3,2)}</div>{mono(f"{round(t["p"]*100)}%",13,"#F2F2F7",ls="-0.02em",extra="width:56px;text-align:right;")}{mono(t["hr"],13,"#AEAEB2",ls="-0.02em",extra="width:56px;text-align:right;")}{mono(t["pct"],13,"#AEAEB2",ls="-0.02em",extra="width:48px;text-align:right;")}{mono(t["st"],13,t["c"],ls="-0.02em",extra="width:48px;text-align:right;")}</div>' for i,t in enumerate(T))
    return [STATUS,header(),sec("Receipt",col(hero,f'<div style="padding-top:12px;">{items}</div>',tot,gap=0),36),
            sec("Goals table",col(row(lab("Goals"),mono("4/5 ON PACE",11,"#AEAEB2",ls="0.06em")),f'<div style="display:flex;flex-direction:column;padding-top:4px;">{gh}{gr}</div>',gap=12),48),CHART,HEAT,STREAK,SPACER,TAB]

# ---------- S5  Centered balance ----------
def s5():
    ticks=''.join(f'<div style="flex:{t["mins"]};height:10px;border-radius:3px;background:{t["c"]};"></div>' for t in T)
    hero=f'<div style="display:flex;flex-direction:column;align-items:center;gap:10px;">{lab("This week")}{pixel(TOTAL,120)}{row(mono("↑ "+DELTA.lstrip("+"),15,UP,ls="-0.02em"),mono("·",13,"#3A3A3C"),mono(f"{DPCT} vs {LAST}",13,"#6C6C70",ls="-0.02em"),gap=8,jc="center",al="baseline")}<div style="display:flex;gap:3px;width:100%;padding-top:14px;">{ticks}</div></div>'
    def tile(t,wide=False):
        w="100%" if wide else "180px"
        return f'<div layer-name="{t["n"]}" style="width:{w};display:flex;flex-direction:column;gap:10px;padding:16px;border-radius:20px;background:#121214;box-sizing:border-box;">{row(row(dot(t["c"],7),tx(t["n"],s=13,w=600,c="#AEAEB2"),gap=8,jc="flex-start"),delta(t,11))}{mono(t["w"],28)}{segs(t["p"],t["c"],t["rgb"],10,4,2)}{row(mono(f"{round(t["p"]*100)}% {t["per"].lower()}",10,"#6C6C70",ls="0.02em"),mono(t["st"],10,t["c"],ls="0.02em"))}{hist(t,"dot",6,4)}</div>'
    tiles='<div style="display:flex;flex-wrap:wrap;gap:12px;justify-content:center;">'+''.join(tile(t) for t in T[:4])+tile(T[4],True)+'</div>'
    rates=f'<div style="display:flex;justify-content:space-between;padding:0 4px;">'+''.join(f'<div style="display:flex;flex-direction:column;align-items:center;gap:4px;">{mono(t["pct"],18)}{dot(t["c"],5)}</div>' for t in T)+'</div>'
    return [STATUS,header(),sec("Total",hero,40),sec("Trackers",col(row(lab("By tracker"),mono("4/5 on pace",12,"#AEAEB2",ls="-0.02em")),tiles,gap=16),44),
            sec("Hit rates",col(row(lab("Goals hit · 12 periods"),gap=0,jc="center"),rates,gap=16),44),CHART,HEAT,STREAK,SPACER,TAB]

for k,f in enumerate([s1,s2,s3,s4,s5],1):
    s=''.join(f()); open(f's{k}.html','w').write(s); print(k,len(s))

import re
def mini(s):
    for a in ["white-space:nowrap;","justify-content:flex-start;","box-sizing:border-box;","align-items:center;justify-content:space-between;gap:12px;"]:
        s=s.replace(a, "align-items:center;justify-content:space-between;" if a.startswith("align-items:center;justify") else "")
    s=s.replace("font-weight:500;","")  # default weight handled? keep explicit below
    return s
for k,f in enumerate([s1,s2,s3,s4,s5],1):
    parts=f()
    # group into chunks under ~9KB
    chunks=[];cur=""
    for p in parts:
        p=p.replace("white-space:nowrap;","").replace("justify-content:flex-start;","").replace("box-sizing:border-box;","")
        if len(cur)+len(p)>9000 and cur: chunks.append(cur);cur=""
        cur+=p
    chunks.append(cur)
    for i,c in enumerate(chunks): open(f's{k}_{i}.html','w').write(c)
    print(k,[len(c) for c in chunks])
