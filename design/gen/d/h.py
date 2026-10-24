exec(open('d6.py').read().split("body=f'''")[0])
REST='<x-paper-clone node-id="5TC-0" /><x-paper-clone node-id="301-0" /><x-paper-clone node-id="2ZA-0" /><x-paper-clone node-id="2Z8-0" />'
META=tx("Weekly · 25h goal · resets Mon",s=13,c="rgba(0,0,0,0.62)")
def chev(c="#000000",w=11,h=18): return f'<svg width="{w}" height="{h}" viewBox="0 0 11 18" fill="none"><path d="M9 2 2 9l7 7" stroke="{c}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>'
CIRCLE=lambda inner,s=44,bg="rgba(0,0,0,0.12)": f'<div layer-name="Back" style="width:{s}px;height:{s}px;border-radius:{s//2}px;background:{bg};display:flex;align-items:center;justify-content:center;flex-shrink:0;">{inner}</div>'
CLOCK=col(row(dot("#000000"),tx("Clocked in · 20:06",s=13,w=600,c="rgba(0,0,0,0.7)"),gap=7,jc="flex-start"),tx("00:50:01","Geist Pixel",92,400,"#000000","0em",90),gap=4)
TICKS=col(segs(.91,6,on="#000000",off="rgba(0,0,0,0.16)"),row(row(mono("22:49",15,"#000000"),mono("of 25h",12,"rgba(0,0,0,0.55)",ls="-0.02em"),gap=5,al="baseline",jc="flex-start"),tx("2h 11m left",s=13,c="rgba(0,0,0,0.55)")),gap=10)
STOPW=f'<div style="padding-top:4px;">{STOPBTN}</div>'
def block(top,content,radius="0 0 30px 30px",extra=""):
    return f'<div layer-name="Accent header" style="display:flex;flex-direction:column;border-radius:{radius};background:{A};padding-bottom:20px;{extra}">{top}<div style="display:flex;flex-direction:column;gap:16px;padding:0 20px;">{content}</div></div>'
TITLE=lambda s=24: col(tx("Deep Work","Geist",s,650,"#000000","-0.02em",s+4),META,gap=1)
# H1 centered nav title (iOS standard)
h1=block(SB+f'<div layer-name="Nav" style="display:flex;align-items:center;padding:4px 16px 20px;">{CIRCLE(chev())}<div style="flex:1;display:flex;justify-content:center;gap:8px;align-items:center;">{ic("target",26,8,14)}{tx("Deep Work","Geist",17,650,"#000000","-0.01em",22)}</div><div style="width:44px;"></div></div>',
  col(tx("Weekly · 25h goal · resets Mon",s=13,c="rgba(0,0,0,0.62)",extra="text-align:center;"),gap=0,extra="display:none;")+CLOCK+TICKS+STOPW)
# H2 iOS back label + large title
h2=block(SB+f'<div layer-name="Nav" style="display:flex;align-items:center;gap:2px;padding:6px 14px 0;height:44px;">{chev(w=11,h=18)}{tx("Trackers","Geist",17,500,"#000000",lh=22,extra="padding-left:6px;")}</div>',
  f'<div style="padding-top:14px;">{row(ic("target",44,13,22),TITLE(28),gap=14,jc="flex-start")}</div>'+CLOCK+TICKS+STOPW)
# H3 sheet: grabber + close, rounded top
GRAB='<div style="display:flex;justify-content:center;padding:8px 0 0;"><div style="width:40px;height:5px;border-radius:3px;background:rgba(0,0,0,0.25);"></div></div>'
X='<svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M2 2l10 10M12 2 2 12" stroke="#000000" stroke-width="2.2" stroke-linecap="round"/></svg>'
h3top=SB+'<div style="height:10px;"></div>'
h3=f'<div layer-name="Sheet backdrop" style="display:flex;flex-direction:column;padding-top:0;">{SB.replace("#000000","#FFFFFF")}<div style="height:8px;"></div>'+block(GRAB+f'<div layer-name="Nav" style="display:flex;align-items:center;gap:12px;padding:10px 16px 18px 20px;">{ic("target",40,12,20)}<div style="flex:1;">{TITLE(22)}</div>{CIRCLE(X,36)}</div>',CLOCK+TICKS+STOPW,radius="28px 28px 30px 30px",extra="margin:0 0;")+'</div>'
# H4 bottom floating toolbar holds back
h4=block(SB+f'<div style="padding:8px 20px 18px;">{row(ic("target",40,12,20),TITLE(24),gap=12,jc="flex-start")}</div>',CLOCK+TICKS+STOPW)
BAR=f'<div layer-name="Bottom bar (glass)" style="position:absolute;left:16px;right:16px;bottom:24px;display:flex;justify-content:space-between;align-items:center;">{CIRCLE(chev("#FFFFFF"),52,"rgba(40,40,44,0.72)").replace("background:","backdrop-filter:blur(24px);border:1px solid rgba(255,255,255,0.14);background:")}<div style="display:flex;align-items:center;gap:8px;height:52px;padding:0 20px;border-radius:26px;backdrop-filter:blur(24px);background:rgba(40,40,44,0.72);border:1px solid rgba(255,255,255,0.14);"><svg width="13" height="13" viewBox="0 0 12 12" fill="none"><path d="M6 1v10M1 6h10" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/></svg>{tx("Add entry",s=15,w=600,c="#FFFFFF")}</div></div>'
# H5 breadcrumb capsule
CAP=f'<div layer-name="Back capsule" style="display:flex;align-items:center;gap:10px;height:44px;padding:0 16px 0 14px;border-radius:22px;background:#000000;">{chev("#FFFFFF",9,15)}<div style="width:1px;height:18px;background:rgba(255,255,255,0.2);"></div><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="{A}" stroke-width="2.2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.2" fill="{A}"/></svg>{tx("Deep Work","Geist",15,600,"#FFFFFF",lh=20)}</div>'
h5=block(SB+f'<div layer-name="Nav" style="display:flex;align-items:center;justify-content:space-between;padding:4px 16px 22px;">{CAP}{tx("Weekly · 25h",s=13,w=600,c="rgba(0,0,0,0.6)")}</div>',CLOCK+TICKS+STOPW)
for k,(h,extra) in enumerate([(h1,""),(h2,""),(h3,""),(h4,BAR),(h5,"")],1):
    open(f'h{k}.html','w').write(h+REST+extra)
    print(k,len(h+REST+extra))

SBW=SB.replace("#000000","#FFFFFF")
for k in range(1,6):
    s=open(f'h{k}.html').read()
    s=s.replace(SBW,'<x-paper-clone node-id="33E-0" />').replace(SB,'<x-paper-clone node-id="5RO-0" />')
    s=s.replace(CLOCK,'<x-paper-clone node-id="5SC-0" />').replace(TICKS,'<x-paper-clone node-id="5SH-0" />').replace(STOPW,'<x-paper-clone node-id="5T8-0" />')
    import re
    s=re.sub(r'<div style="display:flex;flex-direction:column;gap:0px;display:none;">.*?</div></div>','',s,count=1)
    open(f'h{k}.html','w').write(s); print(k,len(s))
