exec(open('gen.py').read().split("CHART=S(")[0])
clean=lambda s: s.replace("white-space:nowrap;","").replace("justify-content:flex-start;","").replace("box-sizing:border-box;","")
exec(open('/tmp/pocus-gen/d/gen.py').read().split("DAYS=")[0].split("A=\"#4A8BE5\"")[1].join(["A=\"#4A8BE5\"",""]) if False else "")
A="#4A8BE5"; RGB="74,139,229"; TINT="#172335"
ICT='<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.2" fill="{c}"/>'
def icon(size=36,stroke="#000000",bg="rgba(0,0,0,0.13)",r=11):
    g=round(size*.5); return f'<div style="width:{size}px;height:{size}px;border-radius:{r}px;background:{bg};display:flex;align-items:center;justify-content:center;flex-shrink:0;"><svg width="{g}" height="{g}" viewBox="0 0 24 24" fill="none" stroke="{stroke}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{ICT.format(c=stroke)}</svg></div>'
X=lambda c="#000000",bg="rgba(0,0,0,0.12)": f'<div layer-name="Close" style="width:34px;height:34px;border-radius:17px;background:{bg};display:flex;align-items:center;justify-content:center;flex-shrink:0;"><svg width="12" height="12" viewBox="0 0 14 14" fill="none"><path d="M2 2l10 10M12 2 2 12" stroke="{c}" stroke-width="2.2" stroke-linecap="round"/></svg></div>'
GRAB=lambda c="rgba(0,0,0,0.25)": f'<div style="display:flex;justify-content:center;padding-top:8px;"><div style="width:40px;height:5px;border-radius:3px;background:{c};"></div></div>'
DAYS=[("M","4:12",252),("T","5:06",306),("W","3:48",228),("T","6:00",360),("F","3:43",223),("S","–",0),("S","–",0)]
def days(h=64,past=f"rgba({RGB},0.45)"):
    out=''.join(f'<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:6px;">{mono(v,9,"#FFFFFF" if i==4 else "#5E5E62",ls="0em")}<div style="align-self:stretch;height:{round(m/360*h) if m else 3}px;border-radius:{4 if m else 2}px;background:{A if i==4 else (past if m else "#1C1C1E")};"></div>{mono(d,10,"#FFFFFF" if i==4 else "#6C6C70",ls="0em")}</div>' for i,(d,v,m) in enumerate(DAYS))
    return f'<div layer-name="By day" style="display:flex;align-items:flex-end;gap:8px;">{out}</div>'
WK=[("AUG 30",1000),("SEP 6",1090),("SEP 13",1025),("SEP 20",1230),("SEP 27",1140),("OCT 4",1275),("OCT 11",1170),("NOW",1369)]
def weeks(h=100):
    mx=1500
    bars=''.join(f'<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:6px;"><div style="align-self:stretch;height:{round(m/mx*h)}px;border-radius:4px;background:{A if i==7 else f"rgba({RGB},0.32)"};"></div>{mono(d,8,"#FFFFFF" if i==7 else "#5E5E62",ls="0.02em")}</div>' for i,(d,m) in enumerate(WK))
    goal=f'<div style="position:absolute;left:0;right:0;top:0;height:0;border-top:1px dashed rgba(255,255,255,0.28);"></div><div style="position:absolute;right:0;top:-16px;">{mono("GOAL 25H",8,"#6C6C70",ls="0.06em")}</div>'
    return f'<div layer-name="8 weeks" style="position:relative;display:flex;align-items:flex-end;gap:6px;padding-top:0;height:{h+19}px;">{goal}{bars}</div>'
def cells():
    t=T[0]; return hist(t,"sq",18,4,flex=True)
def lane():
    segs_=[(1,2,0.45),(4,6,0.45),(7,12,1)]
    o='<div style="position:relative;height:10px;border-radius:5px;background:#161618;">'
    for s,e,a in segs_: o+=f'<div style="position:absolute;left:{(s/12)*100:.1f}%;width:{((e-s)/12)*100-1:.1f}%;top:0;height:10px;border-radius:5px;background:{A if a==1 else f"rgba({RGB},0.45)"};"></div>'
    return o+'</div>'
def quad(c1="#F2F2F7",lab_c="#6C6C70",bg=None):
    items=[("12","sessions"),("1:54","avg session"),("3:45","longest"),("THU","best day")]
    b=f"background:{bg};border-radius:18px;padding:16px;" if bg else ""
    return f'<div layer-name="Numbers" style="display:flex;justify-content:space-between;{b}">'+''.join(col(mono(v,18,c1,ls="-0.02em"),tx(l,s=11,c=lab_c),gap=2) for v,l in items)+'</div>'
def body(pt=36):
    return (S("This week by day",shead("This week","avg 4:34 / day")+days(),pt)
      +S("8 weeks",shead("Last 8 weeks","+17% vs avg")+weeks())
      +S("Goal history",shead("Goal hit · 12 weeks","8/11 · 73%")+cells())
      +S("Streak",shead("Streak","current 5w · best 5w")+lane())
      +S("Numbers",shead("This week")+quad())
      +'<div style="display:flex;justify-content:center;padding:36px 20px 48px;"><div style="display:flex;align-items:center;gap:8px;height:44px;padding:0 18px;border-radius:22px;background:#161618;">'+tx("Open tracker",s=14,w=600,c="#E5E5EA")+CHEV+'</div></div>')
# T1 accent sheet
t1head=f'''<div layer-name="Sheet backdrop" style="display:flex;flex-direction:column;"><x-paper-clone node-id="33E-0" /><div style="height:8px;"></div>
<div layer-name="Accent header" style="display:flex;flex-direction:column;gap:18px;padding-bottom:22px;border-radius:28px 28px 30px 30px;background:{A};">{GRAB()}
<div style="display:flex;align-items:center;gap:12px;padding:2px 16px 0 20px;">{icon(36)}<div style="flex:1;">{col(tx("Deep Work","Geist",20,650,"#000000","-0.02em",24),tx("Weekly · 25h goal",s=13,c="rgba(0,0,0,0.62)"),gap=0)}</div>{X()}</div>
<div style="display:flex;flex-direction:column;gap:10px;padding:0 20px;">{tx("THIS WEEK","Geist Mono",11,500,"rgba(0,0,0,0.6)","0.08em",14)}{row(pixel("22:49",96,"#000000"),col(mono("↑ 3:19",16,"#000000",ls="-0.02em"),mono("+17% vs 19:30",11,"rgba(0,0,0,0.6)",ls="-0.01em"),gap=2,extra="align-items:flex-end;padding-bottom:10px;"),al="flex-end")}
{col(segs(.91,"#000000","0,0,0",h=6),row(mono("91% of 25:00",11,"rgba(0,0,0,0.65)",ls="-0.01em"),mono("2h 11m left",11,"rgba(0,0,0,0.65)",ls="-0.01em")),gap=8)}</div></div></div>'''
T1=t1head+body(32)
# T2 neutral sheet
t2head=f'''<div layer-name="Sheet backdrop" style="display:flex;flex-direction:column;"><x-paper-clone node-id="33E-0" /><div style="height:8px;"></div>
<div layer-name="Sheet header" style="display:flex;flex-direction:column;gap:22px;padding-bottom:4px;border-radius:28px 28px 0 0;background:#141416;">{GRAB("rgba(255,255,255,0.18)")}
<div style="display:flex;align-items:center;gap:12px;padding:2px 16px 0 20px;">{icon(36,A,f"rgba({RGB},0.16)")}<div style="flex:1;">{col(tx("Deep Work","Geist",20,650,"#F2F2F7","-0.02em",24),tx("Weekly · 25h goal",s=13,c="#8E8E93"),gap=0)}</div>{X("#FFFFFF","rgba(255,255,255,0.1)")}</div>
<div style="display:flex;flex-direction:column;align-items:center;gap:8px;padding:6px 20px 24px;">{lab("This week")}{pixel("22:49",112,"#FFFFFF")}{row(mono("↑ 3:19",14,UP,ls="-0.01em"),mono("+17% vs last week",12,"#6C6C70",ls="-0.01em"),gap=10,jc="center",al="baseline")}<div style="width:100%;padding-top:10px;">{col(segs(.91,A,RGB,h=8),row(mono("91% OF 25:00",9,"#6C6C70",ls="0.06em"),mono("2H 11M LEFT",9,"#6C6C70",ls="0.06em")),gap=8)}</div></div></div></div>'''
T2=t2head+'<div style="display:flex;flex-direction:column;background:#141416;">'+body(28)+'</div>'
# T3 pushed page, accent numerals
t3head=f'''<x-paper-clone node-id="80I-0" /><div layer-name="Nav" style="display:flex;align-items:center;gap:4px;padding:6px 14px 0;height:44px;"><svg width="11" height="18" viewBox="0 0 11 18" fill="none"><path d="M9 2 2 9l7 7" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>{tx("Stats","Geist",17,500,"#FFFFFF",lh=22,extra="padding-left:6px;")}</div>
<div layer-name="Title" style="display:flex;align-items:center;gap:12px;padding:16px 20px 0;">{icon(40,"#000000",A,12)}{col(tx("Deep Work","Geist",24,700,"#F2F2F7","-0.02em",28),tx("Weekly · 25h goal",s=13,c="#8E8E93"),gap=0)}</div>
<div layer-name="Hero" style="display:flex;flex-direction:column;gap:10px;padding:28px 20px 0;">{lab("This week")}{row(pixel("22:49",104,A),col(mono("↑ 3:19",16,UP,ls="-0.02em"),mono("+17% · 19:30",11,"#6C6C70",ls="-0.01em"),gap=2,extra="align-items:flex-end;padding-bottom:10px;"),al="flex-end")}{col(segs(.91,A,RGB,h=8),row(mono("91% OF 25:00",9,"#6C6C70",ls="0.06em"),mono("2H 11M LEFT",9,"#6C6C70",ls="0.06em")),gap=8)}</div>'''
T3=t3head+body(44)
for k,s in enumerate([T1,T2,T3],1):
    s=clean(s); open(f't{k}.html','w').write(s); print(k,len(s))
