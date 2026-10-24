exec(open('/tmp/pocus-gen/s/gen.py').read().split("# ---------- S1")[0])
exec(open('/tmp/pocus-gen/r/charts.py').read().split('if __name__')[0])
def shead(l,r="",rc="#AEAEB2"): return row(lab(l),mono(r,12,rc,ls="-0.01em") if r else "")
def S(name,body,pt=44): return f'<div layer-name="{name}" style="display:flex;flex-direction:column;gap:16px;padding:{pt}px 20px 0;">{body}</div>'
def header(): 
    per=''.join(tx(p,"Geist Mono",12,600 if p=="W" else 500,"#FFFFFF" if p=="W" else "#5E5E62","0.04em",16,extra=("padding:6px 10px;border-radius:12px;background:rgba(255,255,255,0.10);" if p=="W" else "padding:6px 10px;")) for p in ["W","M","6M","Y"])
    return f'<div layer-name="Header" style="display:flex;align-items:flex-end;justify-content:space-between;padding:12px 20px 0;">{col(lab("Oct 19 – 25"),tx("Stats","Geist",28,700,"#F2F2F7","-0.02em",34),gap=4)}<div style="display:flex;gap:2px;padding-bottom:2px;">{per}</div></div>'
def m2(t): h,m=t.split(":"); return int(h)*60+int(m)
LASTM={t["n"]:m2(t["l"]) for t in T}
def stack(field,h):
    parts=''.join(f'<div style="width:{(t["mins"] if field=="w" else LASTM[t["n"]])/2187*100:.2f}%;height:{h}px;border-radius:2px;background:{t["c"] if field=="w" else "rgba("+t["rgb"]+",0.32)"};"></div>' for t in T)
    return f'<div style="display:flex;gap:2px;">{parts}</div>'
def split():
    return col(stack("w",10),row(mono("THIS WEEK",9,"#6C6C70",ls="0.08em"),mono(TOTAL,11,"#AEAEB2",ls="-0.01em")),f'<div style="height:4px;"></div>',stack("l",6),row(mono("LAST WEEK",9,"#5E5E62",ls="0.08em"),mono(LAST,11,"#6C6C70",ls="-0.01em")),gap=6)
def hero_center(size=112):
    return f'<div layer-name="Hero" style="display:flex;flex-direction:column;align-items:center;gap:8px;">{lab("This week")}{pixel(TOTAL,size)}{row(mono("↑ 4:15",14,UP,ls="-0.01em"),mono("+13% vs last week",12,"#6C6C70",ls="-0.01em"),gap=10,jc="center",al="baseline")}</div>'
def hero_left(size=104):
    return row(col(lab("This week"),pixel(TOTAL,size),gap=8),col(mono("↑ 4:15",16,UP,ls="-0.02em"),mono("+13% · 32:12",11,"#6C6C70",ls="-0.01em"),gap=2,extra="align-items:flex-end;padding-bottom:10px;"),al="flex-end")
def trend(h=96,labels=True):
    mx=2187
    bars=''.join(f'<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:6px;">{mono(f"{m//60}:{m%60:02d}" if i==7 else "",10,"#FFFFFF",ls="-0.01em") if labels else ""}<div style="align-self:stretch;height:{round(m/mx*h)}px;border-radius:4px;background:{"#F2F2F7" if i==7 else "#26262A"};"></div>{mono(d.split(" ")[0] if i<7 else "NOW",9,"#FFFFFF" if i==7 else "#5E5E62",ls="0.04em")}</div>' for i,(d,m) in enumerate(WEEKS))
    return f'<div layer-name="8-week bars" style="display:flex;align-items:flex-end;gap:6px;">{bars}</div>'
def ledger():
    th=lambda t,w: f'<div style="width:{w}px;display:flex;justify-content:flex-end;">{mono(t,9,"#5E5E62",ls="0.08em")}</div>'
    td=lambda v,w,c="#F2F2F7",s=14: f'<div style="width:{w}px;display:flex;justify-content:flex-end;">{mono(v,s,c,ls="-0.01em")}</div>'
    head=f'<div style="display:flex;align-items:center;padding-bottom:8px;border-bottom:1px solid #1C1C1E;"><div style="flex:1;">{mono("TRACKER",9,"#5E5E62",ls="0.08em")}</div>{th("NOW",60)}{th("LAST",56)}{th("Δ",58)}</div>'
    body=''.join(f'<div style="display:flex;align-items:center;height:44px;border-bottom:1px solid #151517;"><div style="flex:1;display:flex;align-items:center;gap:10px;">{dot(t["c"],6)}{tx(t["n"],s=14,w=500,c="#E5E5EA")}</div>{td(t["w"],60)}{td(t["l"],56,"#5E5E62")}{td(t["d"],58,UP if t["up"] else DOWN,12)}</div>' for t in T)
    foot=f'<div style="display:flex;align-items:center;height:44px;"><div style="flex:1;">{mono("TOTAL",10,"#AEAEB2",ls="0.08em")}</div>{td(TOTAL,60,"#FFFFFF")}{td(LAST,56,"#5E5E62")}{td(DELTA,58,UP,12)}</div>'
    return f'<div layer-name="Tracker table" style="display:flex;flex-direction:column;">{head}{body}{foot}</div>'
CHEV='<svg width="7" height="12" viewBox="0 0 7 12" fill="none"><path d="M1 1l5 5-5 5" stroke="#5E5E62" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>'
def tile(t,w="194px",dots=True):
    return f'<div layer-name="Card — {t["n"]}" style="width:{w};display:flex;flex-direction:column;gap:10px;padding:16px;border-radius:20px;background:#121214;">{row(row(dot(t["c"],7),tx(t["n"],s=13,w=600,c="#AEAEB2"),gap=8,jc="flex-start"),CHEV)}{row(mono(f"{round(t["p"]*100)}%",24),mono(t["st"],11,t["c"],ls="0em"),al="baseline")}{segs(t["p"],t["c"],t["rgb"],h=4)}{mono(t["per"].upper()+" "+t["g"],9,"#6C6C70",ls="0.04em")}{hist(t,"dot",6,4) if dots else ""}</div>'
def tiles():
    return '<div style="display:flex;flex-wrap:wrap;gap:12px;">'+''.join(tile(t) for t in T[:4])+tile(T[4],"100%")+'</div>'
def tile_row(t):
    return f'<div layer-name="Card — {t["n"]}" style="display:flex;align-items:center;gap:14px;padding:14px 16px;border-radius:18px;background:#121214;">{dot(t["c"],8)}<div style="flex:1;display:flex;flex-direction:column;gap:8px;">{row(tx(t["n"],s=14,w=600,c="#E5E5EA"),row(mono(f"{round(t["p"]*100)}%",14),mono(t["st"],11,t["c"],ls="0em"),gap=8,al="baseline"))}{hist(t,"sq",8,3,flex=True)}</div>{CHEV}</div>'
LEGEND=row(*[row(dot(c,6),tx(n,s=11,c="#8E8E93"),gap=6,jc="flex-start") for n,c in [("Deep Work","#4A8BE5"),("Exercise","#1DB3A6"),("Meetings","#F7A23A")]],gap=16,jc="flex-start")
CHART=S("Goal % over time",shead("Goal % · 8 weeks","Deep Work 91% · best")+LINE+LEGEND,48)
HEATS=S("Consistency",shead("Consistency","15 perfect days")+HEAT,48)
STRK=S("Streaks",shead("Streaks · Aug → now","longest")+LANES,48)
TAIL=CHART+HEATS+STRK+'<div style="height:120px;"></div><x-paper-clone node-id="33P-0" />'
TOP='<x-paper-clone node-id="3FT-0" />'+header()
R1=TOP+S("Hero",hero_center()+split(),36)+S("By tracker",shead("Hours by tracker","4/5 on pace")+ledger())+S("Trend",shead("8-week trend","avg 29:42")+trend())+S("Goals",shead("Goals","tap for detail","#5E5E62")+tiles())+TAIL
R2=TOP+S("Hero",hero_left()+trend(80,False)+row(mono("8-WEEK AVG 29:42",9,"#5E5E62",ls="0.06em"),mono("BEST WEEK",9,"#AEAEB2",ls="0.06em")),36)+S("By tracker",shead("Hours by tracker")+split()+ledger())+S("Goals",shead("Goals · last 12","4/5 on pace")+col(*[tile_row(t) for t in T],gap=8))+TAIL
R3=TOP+S("Hero",hero_center(120)+split(),36)+S("Goals",shead("Goals","4/5 on pace")+tiles())+S("Trend",shead("8-week trend","avg 29:42")+trend(84))+S("By tracker",shead("Hours by tracker")+ledger())+TAIL
for k,s in enumerate([R1,R2,R3],1):
    s=s.replace("white-space:nowrap;","").replace("justify-content:flex-start;","")
    open(f'r{k}.html','w').write(s); print(k,len(s))

clean=lambda s: s.replace("white-space:nowrap;","").replace("justify-content:flex-start;","")
parts={"top":TOP,"hero":S("Hero",hero_center()+split(),36),"ledger":S("By tracker",shead("Hours by tracker","4/5 on pace")+ledger()),
 "trend":S("Trend",shead("8-week trend","avg 29:42")+trend()),"goals":S("Goals",shead("Goals","tap for detail","#5E5E62")+tiles()),
 "chart":CHART,"heat":HEATS,"streak":STRK+'<div style="height:120px;"></div><x-paper-clone node-id="33P-0" />'}
for k,v in parts.items(): open(f'p_{k}.html','w').write(clean(v)); print(k,len(clean(v)))

r2hero=S("Hero",hero_left()+trend(72,False)+row(mono("8 WEEKS · AVG 29:42",9,"#5E5E62",ls="0.06em"),mono("BEST WEEK",9,"#AEAEB2",ls="0.06em")),36)
r2goals=S("Goals",shead("Goals · last 12","4/5 on pace")+col(*[tile_row(t) for t in T],gap=8))
open('r2_hero.html','w').write(clean(r2hero)); open('r2_goals.html','w').write(clean(r2goals))
print(len(clean(r2hero)),len(clean(r2goals)))
