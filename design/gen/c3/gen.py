ICONS={
 'target':'<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.2" fill="#000000"/>',
 'people':'<circle cx="9" cy="8" r="3.2"/><path d="M3 19c0-3.3 2.7-5.5 6-5.5s6 2.2 6 5.5"/><circle cx="16.5" cy="9" r="2.6"/><path d="M16.8 13.6c2.5.2 4.2 2 4.2 4.4"/>',
 'pulse':'<path d="M2.5 12h4l2.5-6.5 4.5 13 2.5-6.5h5.5"/>',
 'mail':'<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3.8 6.6 12 12.8l8.2-6.2"/>',
 'book':'<path d="M12 6.5C10 5 7 4.5 3.5 5v13c3.5-.5 6.5 0 8.5 1.5 2-1.5 5-2 8.5-1.5V5C17 4.5 14 5 12 6.5Z"/><path d="M12 6.5v13"/>'}
T=[dict(n="Meetings",c="#F7A23A",rgb="247,162,58",t="#362716",p=.68,v="5:24",m="Weekly · 8h goal",i='people',g="8:00"),
   dict(n="Exercise",c="#1DB3A6",rgb="29,179,166",t="#0F2A29",p=.67,v="0:30",m="Daily · 45m · 6-day streak",i='pulse',g="0:45"),
   dict(n="Email",c="#9D68F0",rgb="157,104,240",t="#261D37",p=.90,v="0:27",m="Daily · 30m goal",i='mail',g="0:30"),
   dict(n="Reading",c="#EF6B6B",rgb="239,107,107",t="#351D1F",p=.64,v="96:10",m="Yearly · 150h goal",i='book',g="150:00")]
R=dict(n="Deep Work",c="#4A8BE5",rgb="74,139,229",t="#172335",p=.91,v="00:50:01",m="Clocked in · 20:06",i='target',g="25:00",wk="22:49 of 25h")
PLAY='<svg width="13" height="15" viewBox="0 0 16 18" fill="#FFFFFF" style="margin-left: 2px;"><path d="M2 1.8c0-1 1.1-1.6 2-1.1l10.7 6.9c.8.5.8 1.7 0 2.2L4 16.7c-.9.5-2-.1-2-1.1z"/></svg>'
def icon(k,size=36,r=11,g=18): return f'<div layer-name="Icon" style="width: {size}px; height: {size}px; border-radius: {r}px; background: rgba(0,0,0,0.13); display: flex; align-items: center; justify-content: center; flex-shrink: 0;"><svg width="{g}" height="{g}" viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{ICONS[k]}</svg></div>'
def play(s=40): return f'<div layer-name="Play" style="width: {s}px; height: {s}px; border-radius: {s//2}px; background: #000000; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">{PLAY}</div>'
def stop(s=52,c="#4A8BE5"): return f'<div layer-name="Stop" style="width: {s}px; height: {s}px; border-radius: {s//2}px; background: #000000; display: flex; align-items: center; justify-content: center; flex-shrink: 0;"><div style="width: {s*0.3:.0f}px; height: {s*0.3:.0f}px; border-radius: 4px; background: {c};"></div></div>'
def segs(d,h=6,gap=3,extra=''):
    n=round(d['p']*20)
    return f'<div layer-name="Segments" style="display: flex; gap: {gap}px; {extra}">'+''.join(f'<div style="flex: 1; height: {h}px; border-radius: 2px; background: {d["c"] if i<n else "rgba("+d["rgb"]+",0.2)"};"></div>' for i in range(20))+'</div>'
def name(t,size=18): return f'<div style="font-family: Geist; font-size: {size}px; font-weight: 600; line-height: {size+4}px; letter-spacing: -0.015em; color: #000000;">{t}</div>'
def meta(t,col="rgba(0,0,0,0.62)"): return f'<div style="font-family: Geist; font-size: 13px; font-weight: 500; line-height: 17px; color: {col};">{t}</div>'
def total(t,size=26,col="#000000"): return f'<div style="font-family: Geist Mono; font-size: {size}px; font-weight: 500; line-height: {size+4}px; letter-spacing: -0.05em; color: {col};">{t}</div>'
def small(t,col): return f'<div style="font-family: Geist Mono; font-size: 12px; font-weight: 500; line-height: 14px; letter-spacing: -0.02em; color: {col};">{t}</div>'
def label(t,col="#AEAEB2"): return f'<div style="font-family: Geist; font-size: 13px; font-weight: 600; line-height: 16px; color: {col};">{t}</div>'

# ---- variant builders: return (running_html, idle_html_fn)
def v1():  # tight 4px frame, inner padding 14, segments aligned to inner text (4+14=18)
    def idle(d):
        return f'''<div layer-name="Tracker — {d["n"]}" style="display: flex; flex-direction: column; gap: 12px; padding: 4px 4px 14px; border-radius: 26px; background: {d["t"]};">
<div style="display: flex; align-items: center; gap: 12px; padding: 14px; border-radius: 22px; background: {d["c"]};">{icon(d["i"])}<div style="flex: 1; display: flex; flex-direction: column; gap: 1px;">{name(d["n"])}{meta(d["m"])}</div>{total(d["v"])}{play()}</div>
{segs(d,6,3,"margin: 0 18px;")}</div>'''
    d=R
    run=f'''<div layer-name="Running — Deep Work" style="display: flex; flex-direction: column; gap: 12px; padding: 12px 4px 14px; border-radius: 26px; background: {d["t"]};">
<div style="display: flex; justify-content: space-between; align-items: center; padding: 0 18px;"><div style="display: flex; align-items: center; gap: 7px;"><div style="width: 7px; height: 7px; border-radius: 4px; background: {d["c"]};"></div>{label(d["m"])}</div>{small(d["wk"],"#8E8E93")}</div>
<div style="display: flex; align-items: center; gap: 12px; padding: 14px; border-radius: 22px; background: {d["c"]};"><div style="flex: 1; display: flex; flex-direction: column; gap: 4px;"><div style="display: flex; align-items: center; gap: 10px;">{icon(d["i"],30,9,16)}{name(d["n"],20)}</div>{total(d["v"],46)}</div>{stop()}</div>
{segs(d,6,3,"margin: 0 18px;")}</div>'''
    return run,idle
def v2():  # time moves to strip next to segments
    def idle(d):
        return f'''<div layer-name="Tracker — {d["n"]}" style="display: flex; flex-direction: column; gap: 10px; padding: 5px 5px 12px; border-radius: 26px; background: {d["t"]};">
<div style="display: flex; align-items: center; gap: 12px; padding: 12px 12px 12px 14px; border-radius: 21px; background: {d["c"]};">{icon(d["i"])}<div style="flex: 1; display: flex; flex-direction: column; gap: 1px;">{name(d["n"])}{meta(d["m"])}</div>{play()}</div>
<div style="display: flex; align-items: center; gap: 14px; padding: 0 14px 0 19px;"><div style="flex: 1;">{segs(d,6,3)}</div><div style="display: flex; align-items: baseline; gap: 3px;">{total(d["v"],18,"#FFFFFF")}{small("/"+d["g"],"#6C6C70")}</div></div></div>'''
    d=R
    run=f'''<div layer-name="Running — Deep Work" style="display: flex; flex-direction: column; gap: 10px; padding: 5px 5px 12px; border-radius: 26px; background: {d["t"]};">
<div style="display: flex; align-items: center; gap: 12px; padding: 14px 14px 14px 16px; border-radius: 21px; background: {d["c"]};"><div style="flex: 1; display: flex; flex-direction: column; gap: 4px;"><div style="display: flex; align-items: center; gap: 10px;">{icon(d["i"],30,9,16)}{name(d["n"],20)}</div>{total(d["v"],46)}{meta(d["m"])}</div>{stop()}</div>
<div style="display: flex; align-items: center; gap: 14px; padding: 0 14px 0 19px;"><div style="flex: 1;">{segs(d,6,3)}</div><div style="display: flex; align-items: baseline; gap: 3px;">{total("22:49",18,"#FFFFFF")}{small("/25:00","#6C6C70")}</div></div></div>'''
    return run,idle
def v3():  # even 8px bezel all around, segments inside bright block bottom? no: strip equal 8
    def idle(d):
        return f'''<div layer-name="Tracker — {d["n"]}" style="display: flex; flex-direction: column; gap: 8px; padding: 8px; border-radius: 28px; background: {d["t"]};">
<div style="display: flex; align-items: center; gap: 12px; padding: 14px; border-radius: 20px; background: {d["c"]};">{icon(d["i"])}<div style="flex: 1; display: flex; flex-direction: column; gap: 1px;">{name(d["n"])}{meta(d["m"])}</div>{total(d["v"])}{play()}</div>
{segs(d,8,3,"padding: 2px 6px 4px;")}</div>'''
    d=R
    run=f'''<div layer-name="Running — Deep Work" style="display: flex; flex-direction: column; gap: 8px; padding: 8px; border-radius: 28px; background: {d["t"]};">
<div style="display: flex; justify-content: space-between; align-items: center; padding: 6px 8px 0;"><div style="display: flex; align-items: center; gap: 7px;"><div style="width: 7px; height: 7px; border-radius: 4px; background: {d["c"]};"></div>{label(d["m"])}</div>{small(d["wk"],"#8E8E93")}</div>
<div style="display: flex; align-items: center; gap: 12px; padding: 14px; border-radius: 20px; background: {d["c"]};"><div style="flex: 1; display: flex; flex-direction: column; gap: 4px;"><div style="display: flex; align-items: center; gap: 10px;">{icon(d["i"],30,9,16)}{name(d["n"],20)}</div>{total(d["v"],46)}</div>{stop()}</div>
{segs(d,8,3,"padding: 2px 6px 4px;")}</div>'''
    return run,idle
def v4():  # flush split: one pill, top bright, bottom tinted band, no nesting
    def idle(d):
        return f'''<div layer-name="Tracker — {d["n"]}" style="display: flex; flex-direction: column; border-radius: 24px; background: {d["t"]}; overflow: hidden;">
<div style="display: flex; align-items: center; gap: 12px; padding: 16px 16px 14px; background: {d["c"]};">{icon(d["i"])}<div style="flex: 1; display: flex; flex-direction: column; gap: 1px;">{name(d["n"])}{meta(d["m"])}</div>{total(d["v"])}{play()}</div>
{segs(d,6,3,"padding: 12px 16px 14px;")}</div>'''
    d=R
    run=f'''<div layer-name="Running — Deep Work" style="display: flex; flex-direction: column; border-radius: 24px; background: {d["t"]}; overflow: hidden;">
<div style="display: flex; flex-direction: column; gap: 10px; padding: 16px; background: {d["c"]};"><div style="display: flex; justify-content: space-between; align-items: center;"><div style="display: flex; align-items: center; gap: 7px;"><div style="width: 7px; height: 7px; border-radius: 4px; background: #000000;"></div>{label(d["m"],"rgba(0,0,0,0.72)")}</div>{small(d["wk"],"rgba(0,0,0,0.6)")}</div>
<div style="display: flex; align-items: center; gap: 12px;"><div style="flex: 1; display: flex; flex-direction: column; gap: 4px;"><div style="display: flex; align-items: center; gap: 10px;">{icon(d["i"],30,9,16)}{name(d["n"],20)}</div>{total(d["v"],46)}</div>{stop()}</div></div>
{segs(d,6,3,"padding: 12px 16px 14px;")}</div>'''
    return run,idle
def v5():  # compact: single bright row; strip has meta + pct + segments
    def idle(d):
        return f'''<div layer-name="Tracker — {d["n"]}" style="display: flex; flex-direction: column; gap: 10px; padding: 5px 5px 14px; border-radius: 26px; background: {d["t"]};">
<div style="display: flex; align-items: center; gap: 12px; padding: 10px 10px 10px 12px; border-radius: 21px; background: {d["c"]};">{icon(d["i"],34,10,17)}<div style="flex: 1;">{name(d["n"])}</div>{total(d["v"],24)}{play(38)}</div>
<div style="display: flex; flex-direction: column; gap: 8px; padding: 0 17px;"><div style="display: flex; justify-content: space-between;">{meta(d["m"],"#8E8E93")}{small(str(round(d["p"]*100))+"%","#AEAEB2")}</div>{segs(d,5,3)}</div></div>'''
    d=R
    run=f'''<div layer-name="Running — Deep Work" style="display: flex; flex-direction: column; gap: 10px; padding: 5px 5px 14px; border-radius: 26px; background: {d["t"]};">
<div style="display: flex; align-items: center; gap: 12px; padding: 14px 12px 14px 16px; border-radius: 21px; background: {d["c"]};"><div style="flex: 1; display: flex; flex-direction: column; gap: 4px;"><div style="display: flex; align-items: center; gap: 10px;">{icon(d["i"],30,9,16)}{name(d["n"],20)}</div>{total(d["v"],46)}</div>{stop()}</div>
<div style="display: flex; flex-direction: column; gap: 8px; padding: 0 17px;"><div style="display: flex; justify-content: space-between;">{label(d["m"])}{small(d["wk"],"#AEAEB2")}</div>{segs(d,5,3)}</div></div>'''
    return run,idle
for k,f in enumerate([v1,v2,v3,v4,v5],1):
    run,idle=f()
    html=f'<div layer-name="Trackers" style="display: flex; flex-direction: column; gap: 14px; padding: 4px 12px 0;">'+run+''.join(idle(d) for d in T)+'</div>'
    open(f'/tmp/pocus-gen/c3/v{k}.html','w').write(html)
    print(k,len(html))
