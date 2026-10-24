src=open('/tmp/pocus-gen/f/gen.py').read().split("# ---------- 2")[0]
exec(src.replace('NEW=backdrop+sheet',''))
K="#000000"
def prev(pad="12px 12px 12px 14px",name="Guitar",sub="Daily · 30m goal"):
    return f'''<div layer-name="Preview — Guitar" style="display:flex;flex-direction:column;padding:5px;border-radius:26px;background:{PT};"><div style="display:flex;align-items:center;gap:12px;padding:{pad};border-radius:21px;background:{P};">{ICON("music",36,11,18)}<div style="flex:1;display:flex;flex-direction:column;gap:1px;"><div style="display:flex;align-items:center;gap:2px;">{tx(name,"Geist",18,600,K,"-0.015em",22)}<div style="width:2px;height:20px;background:#000000;"></div></div>{tx(sub,s=13,c="rgba(0,0,0,0.62)")}</div>{mono("0:00",26,K,ls="-0.05em")}{PLAYB()}</div></div>'''
grab=lambda c="rgba(255,255,255,0.18)": f'<div style="display:flex;justify-content:center;padding-top:8px;"><div style="width:40px;height:5px;border-radius:3px;background:{c};"></div></div>'
nav=lambda t="New tracker",right=None: f'<div layer-name="Nav" style="display:flex;align-items:center;padding:12px 16px 0;">{circ(X)}<div style="flex:1;display:flex;justify-content:center;">{tx(t,"Geist",17,650,"#F2F2F7","-0.01em",22)}</div>{right if right is not None else circ(CHK,P)}</div>'
pill=lambda t,bg=P,c=K: f'<div layer-name="Create" style="display:flex;justify-content:center;align-items:center;height:56px;border-radius:28px;background:{bg};">{tx(t,"Geist",17,650,c,"-0.01em",22)}</div>'
def sheet(top,body,bg="#141416",name="Sheet"):
    return f'<div layer-name="{name}" style="position:absolute;left:0;right:0;bottom:0;top:{top}px;display:flex;flex-direction:column;border-radius:30px 30px 0 0;background:{bg};">{body}</div>'
iconrow=lambda s=52,r=16: ''.join(circ(f'<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="{K if k=="music" else "#8E8E93"}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{ICONS[k]}</svg>',P if k=="music" else "#1C1C1E",s).replace(f"border-radius:{s//2}px",f"border-radius:{r}px") for k in ["target","people","pulse","mail","book","music"])
def seg_(sel="DAY",bg="#1C1C1E"):
    s=''.join(tx(p,"Geist Mono",12,600 if p==sel else 500,K if p==sel else "#8E8E93","0.06em",16,extra=f"flex:1;text-align:center;padding:10px 0;border-radius:12px;{'background:#F2F2F7;' if p==sel else ''}") for p in ["DAY","WEEK","MONTH","YEAR"])
    return f'<div style="display:flex;gap:4px;padding:4px;border-radius:16px;background:{bg};">{s}</div>'
row2=lambda a,b: f'<div style="display:flex;justify-content:space-between;">{a}</div>'
D='<div style="height:1px;background:rgba(255,255,255,0.06);"></div>'

# ---- N1 Sentence builder
chip=lambda t,f="Geist",bg=P,c=K,ls="-0.02em": f'<div style="display:flex;align-items:center;padding:4px 12px;border-radius:12px;background:{bg};">{tx(t,f,26,600,c,ls,34)}</div>'
w=lambda t: tx(t,"Geist",26,500,"#6C6C70","-0.02em",34)
sentence=f'''<div layer-name="Sentence" style="display:flex;flex-direction:column;gap:10px;padding:30px 20px 0;"><div style="display:flex;align-items:center;gap:10px;">{w("Track")}{chip("Guitar")}</div><div style="display:flex;align-items:center;gap:10px;">{w("for")}{chip("0:30","Geist Mono",bg="#1C1C1E",c="#F2F2F7",ls="-0.04em")}{w("every")}{chip("day",bg="#1C1C1E",c="#F2F2F7")}</div></div>'''
N1=backdrop+sheet(250,f'''{grab()}{nav()}<div style="padding:22px 12px 0;">{prev()}</div>{sentence}
<div style="display:flex;flex-direction:column;gap:12px;padding:34px 20px 0;">{lab("Look")}<div style="display:flex;justify-content:space-between;">{iconrow()}</div><div style="display:flex;justify-content:space-between;padding-top:6px;">{colors}</div></div>''')

# ---- N2 Accent header sheet (H3 style)
hdr=f'''<div layer-name="Accent header" style="display:flex;flex-direction:column;padding-bottom:22px;border-radius:30px 30px 0 0;background:{P};">{grab("rgba(0,0,0,0.25)")}<div style="display:flex;align-items:center;padding:12px 16px 0;">{circ(X.replace("#FFFFFF","#000000"),"rgba(0,0,0,0.12)")}<div style="flex:1;"></div>{circ(CHK.replace("#000000","#FFFFFF"),K)}</div><div style="display:flex;align-items:center;gap:14px;padding:22px 22px 0;">{ICON("music",52,16,26)}<div style="flex:1;display:flex;flex-direction:column;gap:2px;"><div style="display:flex;align-items:center;gap:3px;">{tx("Guitar","Geist",32,650,K,"-0.025em",38)}<div style="width:2px;height:32px;background:#000000;"></div></div>{tx("Daily · 30m goal",s=14,c="rgba(0,0,0,0.6)",lh=18)}</div></div></div>'''
N2=backdrop+sheet(250,f'''{hdr}
{sec("Icon",f'<div style="display:flex;justify-content:space-between;">{iconrow()}</div>',24)}
{sec("Color",f'<div style="display:flex;justify-content:space-between;">{colors}</div>',24)}
{sec("Track per",seg_(),24)}
<div style="display:flex;align-items:flex-end;justify-content:space-between;padding:24px 20px 0;"><div style="display:flex;flex-direction:column;gap:6px;">{lab("Goal per day")}{mono("0:30",36,"#F2F2F7")}</div><div style="display:flex;gap:10px;">{circ(minus,"#1C1C1E")}{circ(plus,"#1C1C1E")}</div></div>''',bg="#141416")

# ---- N3 Grouped list
def grow(l,right,h=56): return f'<div style="display:flex;align-items:center;justify-content:space-between;height:{h}px;padding:0 16px;">{tx(l,"Geist",16,500,"#F2F2F7",None,20)}{right}</div>'
CHEV='<svg width="7" height="12" viewBox="0 0 7 12" fill="none"><path d="M1 1l5 5-5 5" stroke="#6C6C70" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>'
grp=lambda inner: f'<div style="display:flex;flex-direction:column;border-radius:20px;background:#1C1C1E;">{inner}</div>'
iconval=f'<div style="display:flex;align-items:center;gap:10px;">{ICON("music",28,8,15,P,f"rgba({PRGB},0.16)")}{CHEV}</div>'
colval=f'<div style="display:flex;align-items:center;gap:10px;">{tx("Pink",s=15,c="#8E8E93")}<div style="width:22px;height:22px;border-radius:11px;background:{P};"></div>{CHEV}</div>'
stp=f'<div style="display:flex;align-items:center;gap:6px;">{circ(minus,"#2A2A2E",34)}{mono("0:30",18,"#F2F2F7",ls="-0.03em",extra="width:52px;text-align:center;")}{circ(plus,"#2A2A2E",34)}</div>'
nameval=f'<div style="display:flex;align-items:center;gap:2px;">{tx("Guitar","Geist",16,600,"#F2F2F7",None,20)}<div style="width:2px;height:18px;background:{P};"></div></div>'
N3=backdrop+sheet(180,f'''{grab()}{nav("New tracker",'<div style="width:44px;"></div>')}<div style="padding:22px 12px 0;">{prev()}</div>
<div style="display:flex;flex-direction:column;gap:12px;padding:24px 12px 0;">{grp(grow("Name",nameval)+D+grow("Icon",iconval)+D+grow("Color",colval))}
{grp(f'<div style="padding:12px 12px 0;">{seg_(bg="#141416")}</div>'+grow("Goal per day",stp,64))}</div>
<div style="flex:1;"></div><div style="padding:0 16px 40px;">{pill("Create tracker")}</div>''')
for k,s in {"n1":N1,"n2":N2,"n3":N3}.items():
    s=s.replace("\n",""); open(f'/tmp/pocus-gen/n/{k}.html','w').write(s); print(k,len(s))
