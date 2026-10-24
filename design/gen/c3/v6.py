exec(open('gen.py').read().split("# ---- variant builders")[0])
def pix(t,s): return f'<div style="font-family:Geist Pixel;font-size:{s}px;font-weight:400;line-height:{s}px;color:#000000;">{t}</div>'
def strip(d): return f'<div style="padding:0 17px 0 19px;">{segs(d,6,3)}</div>'
def idle(d):
    return f'''<div layer-name="Tracker — {d["n"]}" style="display:flex;flex-direction:column;gap:10px;padding:5px 5px 12px;border-radius:26px;background:{d["t"]};"><div style="display:flex;align-items:center;gap:12px;padding:12px 12px 12px 14px;border-radius:21px;background:{d["c"]};">{icon(d["i"])}<div style="flex:1;display:flex;flex-direction:column;gap:1px;">{name(d["n"])}{meta(d["m"])}</div>{total(d["v"])}{play()}</div>{strip(d)}</div>'''
d=R
run=f'''<div layer-name="Running — Deep Work" style="display:flex;flex-direction:column;gap:10px;padding:5px 5px 12px;border-radius:26px;background:{d["t"]};"><div style="display:flex;align-items:center;gap:12px;padding:14px 14px 14px 16px;border-radius:21px;background:{d["c"]};"><div style="flex:1;display:flex;flex-direction:column;gap:6px;"><div style="display:flex;align-items:center;gap:10px;">{icon(d["i"],30,9,16)}{name(d["n"],20)}</div>{pix("00:50:01",62)}{meta("Clocked in · 20:06 · 22:49 of 25h")}</div>{stop()}</div>{strip(d)}</div>'''
html='<div layer-name="Trackers" style="display:flex;flex-direction:column;gap:14px;padding:4px 12px 0;">'+run+''.join(idle(x) for x in T)+'</div>'
html=html.replace("; ",";").replace("\n","")
open('v6.html','w').write(html); print(len(html))
