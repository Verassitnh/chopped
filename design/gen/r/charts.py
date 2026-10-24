import re,random
# --- heatmap re-layout to 400 wide
src=open('/tmp/pocus-gen/v3/heat2.html').read()
cells=re.findall(r'<rect x="(\d+)" y="(\d+)" width="22" height="22" rx="6" (fill="[^"]+"(?: stroke="[^"]+" stroke-dasharray="[^"]+")?)/>',src)
cols=sorted(set(int(x) for x,_,_ in cells)); rows=sorted(set(int(y) for _,y,_ in cells))
W=400; LW=22; gap=4; n=len(cols); cw=(W-LW-gap*(n-1))/n
o=[f'<svg layer-name="Daily heatmap" width="{W}" height="{int(14+7*(cw+gap))}" viewBox="0 0 {W} {int(14+7*(cw+gap))}" fill="none">']
for m,ci in (("AUG",0),("SEP",5),("OCT",9)): o.append(f'<text x="{LW+ci*(cw+gap):.1f}" y="9" font-family="Geist Mono" font-size="9" letter-spacing="0.6" fill="#5E5E62">{m}</text>')
for d,ri in (("M",1),("W",3),("F",5)): o.append(f'<text x="0" y="{14+ri*(cw+gap)+cw/2+3:.1f}" font-family="Geist Mono" font-size="9" fill="#5E5E62">{d}</text>')
for x,y,f in cells:
    c=cols.index(int(x)); r=rows.index(int(y))
    f=f.replace('#161616','#161618').replace('#262626','#3A3A3C')
    o.append(f'<rect x="{LW+c*(cw+gap):.1f}" y="{14+r*(cw+gap):.1f}" width="{cw:.1f}" height="{cw:.1f}" rx="5" {f}/>')
o.append('</svg>'); HEAT=''.join(o)
# --- line chart: soften labels
LINE=open('/tmp/pocus-gen/v3/line.html').read().replace('#4E4E4E','#5E5E62').replace('#CFCFCF','#AEAEB2').replace('font-size="10"','font-size="9"').replace(' stroke-opacity="0.7"','').replace('stroke="#F7A23A" stroke-width="1.6"','stroke="rgba(247,162,58,0.7)" stroke-width="1.6"').replace('stroke="#1DB3A6" stroke-width="1.6"','stroke="rgba(29,179,166,0.7)" stroke-width="1.6"')
# --- streak lanes, value on the side
exec(open('/tmp/pocus-gen/v3/lanes2.py').read().split("W=400")[0])
W=400; rowH=28; x0=78; x1=W-34; px=(x1-x0)/84
o=[f'<svg layer-name="Streak timeline" width="{W}" height="{len(lanes)*rowH}" viewBox="0 0 {W} {len(lanes)*rowH}" fill="none">']
for k,(name,c,arr,best) in enumerate(lanes):
    cy=k*rowH+rowH/2
    o.append(f'<text x="0" y="{cy+3.5:.1f}" font-family="Geist Mono" font-size="9" letter-spacing="0.5" fill="#6C6C70">{name}</text>')
    o.append(f'<rect x="{x0}" y="{cy-4:.1f}" width="{x1-x0}" height="8" rx="4" fill="#161618"/>')
    st=streaks(arr); bl=max(l for _,l in st)
    for s,l in st:
        w=max(l*px-1.2,3)

        o.append(f'<rect x="{x0+s*px:.1f}" y="{cy-4:.1f}" width="{w:.1f}" height="8" rx="{min(4,w/2):.1f}" fill="{c if l==bl else "rgba("+",".join(str(int(c[i:i+2],16)) for i in (1,3,5))+",0.45)"}"/>')
    o.append(f'<text x="{W}" y="{cy+3.5:.1f}" text-anchor="end" font-family="Geist Mono" font-size="11" fill="#AEAEB2">{best.lower()}</text>')
o.append('</svg>'); LANES=''.join(o)
if __name__=="__main__": print(len(HEAT),len(LINE),len(LANES))
